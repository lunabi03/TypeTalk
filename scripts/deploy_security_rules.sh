#!/bin/bash

# Firebase Security Rules 배포 스크립트
# TypeTalk 프로젝트의 Firestore 보안 규칙을 안전하게 배포합니다.

set -e  # 오류 시 스크립트 중단

echo "🔒 Firebase Security Rules 배포 시작..."

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 함수 정의
print_step() {
    echo -e "${BLUE}📋 $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# 필수 파일 존재 확인
print_step "필수 파일 확인..."

if [ ! -f "firestore.rules" ]; then
    print_error "firestore.rules 파일이 없습니다!"
    exit 1
fi

if [ ! -f "firebase.json" ]; then
    print_error "firebase.json 파일이 없습니다!"
    exit 1
fi

print_success "필수 파일 확인 완료"

# Firebase CLI 설치 확인
print_step "Firebase CLI 확인..."

if ! command -v firebase &> /dev/null; then
    print_error "Firebase CLI가 설치되지 않았습니다!"
    echo "설치 명령어: npm install -g firebase-tools"
    exit 1
fi

print_success "Firebase CLI 확인 완료"

# Firebase 로그인 확인
print_step "Firebase 인증 확인..."

if ! firebase projects:list &> /dev/null; then
    print_warning "Firebase에 로그인이 필요합니다."
    firebase login
fi

print_success "Firebase 인증 확인 완료"

# 현재 프로젝트 확인
print_step "현재 Firebase 프로젝트 확인..."

PROJECT_ID=$(firebase use | grep "Active" | awk '{print $3}' | tr -d '()')
if [ -z "$PROJECT_ID" ]; then
    print_error "활성 Firebase 프로젝트가 설정되지 않았습니다!"
    echo "프로젝트 설정: firebase use [PROJECT_ID]"
    exit 1
fi

echo "현재 프로젝트: $PROJECT_ID"
print_success "프로젝트 확인 완료"

# 보안 규칙 유효성 검사
print_step "보안 규칙 유효성 검사..."

if ! firebase firestore:rules:validate; then
    print_error "보안 규칙에 오류가 있습니다!"
    exit 1
fi

print_success "보안 규칙 유효성 검사 통과"

# 현재 활성 규칙 백업
print_step "현재 보안 규칙 백업..."

BACKUP_DIR="backups"
mkdir -p $BACKUP_DIR

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="$BACKUP_DIR/firestore_rules_backup_$TIMESTAMP.rules"

if firebase firestore:rules:get > "$BACKUP_FILE" 2>/dev/null; then
    print_success "보안 규칙 백업 완료: $BACKUP_FILE"
else
    print_warning "기존 규칙 백업 실패 (처음 배포일 수 있음)"
fi

# 프로덕션 배포 확인
if [ "$1" = "--production" ] || [ "$1" = "-p" ]; then
    print_warning "⚠️  프로덕션 환경에 배포하려고 합니다!"
    echo "프로젝트: $PROJECT_ID"
    echo "배포할 규칙 파일: firestore.rules"
    echo ""
    read -p "정말 배포하시겠습니까? (yes/no): " confirmation
    
    if [ "$confirmation" != "yes" ]; then
        print_error "배포가 취소되었습니다."
        exit 1
    fi
    
    DEPLOY_ENV="production"
else
    DEPLOY_ENV="development"
fi

# 보안 규칙 배포
print_step "보안 규칙 배포 중..."

if firebase deploy --only firestore:rules; then
    print_success "보안 규칙 배포 완료!"
else
    print_error "보안 규칙 배포 실패!"
    
    # 백업이 있으면 복원 옵션 제공
    if [ -f "$BACKUP_FILE" ]; then
        echo ""
        read -p "백업된 규칙으로 복원하시겠습니까? (yes/no): " restore_confirmation
        
        if [ "$restore_confirmation" = "yes" ]; then
            print_step "백업 규칙 복원 중..."
            
            # 백업 파일을 임시 규칙 파일로 복사
            cp "$BACKUP_FILE" "firestore.rules.backup"
            mv "firestore.rules" "firestore.rules.failed"
            mv "firestore.rules.backup" "firestore.rules"
            
            # 백업 규칙 배포
            if firebase deploy --only firestore:rules; then
                print_success "백업 규칙 복원 완료"
            else
                print_error "백업 규칙 복원 실패"
                mv "firestore.rules.failed" "firestore.rules"
            fi
        fi
    fi
    
    exit 1
fi

# 배포 후 검증
print_step "배포된 규칙 검증..."

sleep 2  # 배포가 완전히 적용될 때까지 대기

if firebase firestore:rules:get > /dev/null 2>&1; then
    print_success "배포된 규칙 검증 완료"
else
    print_error "배포된 규칙 검증 실패"
fi

# 배포 로그 기록
LOG_FILE="$BACKUP_DIR/deployment_log.txt"
echo "$(date '+%Y-%m-%d %H:%M:%S') - 보안 규칙 배포 완료 ($DEPLOY_ENV)" >> "$LOG_FILE"
echo "  프로젝트: $PROJECT_ID" >> "$LOG_FILE"
echo "  백업 파일: $BACKUP_FILE" >> "$LOG_FILE"
echo "" >> "$LOG_FILE"

# 완료 메시지
echo ""
echo "🎉 Firebase Security Rules 배포가 성공적으로 완료되었습니다!"
echo ""
echo "📋 배포 정보:"
echo "  환경: $DEPLOY_ENV"
echo "  프로젝트: $PROJECT_ID"
echo "  백업 파일: $BACKUP_FILE"
echo "  로그 파일: $LOG_FILE"
echo ""
echo "🔍 다음 단계:"
echo "  1. Firebase 콘솔에서 규칙 확인"
echo "  2. 앱에서 기능 테스트"
echo "  3. 보안 규칙 테스트 실행: npm run emulator:test"
echo ""

# 테스트 실행 옵션
if [ "$1" = "--with-test" ] || [ "$1" = "-t" ]; then
    print_step "보안 규칙 테스트 실행..."
    npm run emulator:test
fi
