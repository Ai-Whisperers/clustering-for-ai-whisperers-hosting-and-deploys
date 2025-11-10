#!/bin/bash
# Backup Verification Script
# Doc-Type: Automation Script · Version 1.0 · Updated 2025-11-10

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

verify_velero_backups() {
    log_info "Verifying Velero backups..."

    if ! command -v velero >/dev/null 2>&1; then
        log_error "velero CLI not found"
        return 1
    fi

    log_info "Recent backups:"
    velero backup get

    log_info "\nChecking backup status..."
    FAILED_BACKUPS=$(velero backup get -o json | jq -r '.items[] | select(.status.phase == "Failed") | .metadata.name')

    if [ -n "$FAILED_BACKUPS" ]; then
        log_error "Failed backups found:"
        echo "$FAILED_BACKUPS"
        return 1
    else
        log_info "All backups are successful"
    fi

    log_info "\nChecking backup schedules..."
    velero schedule get
}

verify_etcd_backups() {
    log_info "Verifying etcd backup cronjobs..."

    CRONJOB_STATUS=$(kubectl get cronjob etcd-snapshot -n etcd-backup -o jsonpath='{.status.lastScheduleTime}' 2>/dev/null || echo "")

    if [ -z "$CRONJOB_STATUS" ]; then
        log_error "etcd backup cronjob not found or never run"
        return 1
    fi

    log_info "Last scheduled: $CRONJOB_STATUS"

    log_info "\nRecent backup jobs:"
    kubectl get jobs -n etcd-backup --sort-by=.metadata.creationTimestamp | tail -5

    log_info "\nChecking for failed jobs..."
    FAILED_JOBS=$(kubectl get jobs -n etcd-backup -o json | jq -r '.items[] | select(.status.failed > 0) | .metadata.name')

    if [ -n "$FAILED_JOBS" ]; then
        log_error "Failed backup jobs found:"
        echo "$FAILED_JOBS"
        return 1
    else
        log_info "No failed backup jobs"
    fi
}

verify_s3_backups() {
    log_info "Verifying S3 backup storage..."

    if ! command -v aws >/dev/null 2>&1; then
        log_warn "AWS CLI not found, skipping S3 verification"
        return 0
    fi

    log_info "Velero backups in S3:"
    aws s3 ls s3://k8s-cluster-backups/velero/ --human-readable --summarize | tail -5

    log_info "\netcd snapshots in S3:"
    aws s3 ls s3://k8s-etcd-snapshots/cluster-01/ --human-readable --summarize | tail -5
}

verify_backup_storage_locations() {
    log_info "Verifying Velero backup storage locations..."

    velero backup-location get

    UNAVAILABLE_LOCATIONS=$(velero backup-location get -o json | jq -r '.items[] | select(.status.phase == "Unavailable") | .metadata.name')

    if [ -n "$UNAVAILABLE_LOCATIONS" ]; then
        log_error "Unavailable backup storage locations:"
        echo "$UNAVAILABLE_LOCATIONS"
        return 1
    else
        log_info "All backup storage locations are available"
    fi
}

test_restore() {
    log_info "Testing restore capability (dry-run)..."

    LATEST_BACKUP=$(velero backup get -o json | jq -r '.items | sort_by(.metadata.creationTimestamp) | last | .metadata.name')

    if [ -z "$LATEST_BACKUP" ]; then
        log_error "No backups found for restore test"
        return 1
    fi

    log_info "Testing restore from backup: $LATEST_BACKUP"
    velero restore create test-restore-$(date +%s) \
        --from-backup "$LATEST_BACKUP" \
        --include-namespaces dev \
        --dry-run

    log_info "Dry-run restore test passed"
}

generate_report() {
    log_info "\n========================================="
    log_info "Backup Verification Summary"
    log_info "========================================="

    echo ""
    log_info "Velero Backup Status:"
    velero backup get | tail -5

    echo ""
    log_info "etcd Backup Jobs:"
    kubectl get jobs -n etcd-backup --sort-by=.metadata.creationTimestamp | tail -3

    echo ""
    log_info "Backup Storage Locations:"
    velero backup-location get

    echo ""
    log_info "Verification completed at $(date)"
}

main() {
    log_info "Starting backup verification..."

    verify_velero_backups || log_error "Velero backup verification failed"
    verify_etcd_backups || log_error "etcd backup verification failed"
    verify_s3_backups || log_warn "S3 backup verification skipped or failed"
    verify_backup_storage_locations || log_error "Backup storage location verification failed"
    test_restore || log_error "Restore test failed"

    generate_report

    log_info "\nBackup verification completed"
}

main "$@"
