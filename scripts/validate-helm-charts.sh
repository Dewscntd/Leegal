#!/bin/bash

# Validate Helm Charts for ContractAnalyzer
# This script validates the structure and syntax of Helm charts

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Configuration
CHART_DIR="deploy/charts/contract-analyzer"
SERVICES=("api-gateway" "auth" "analysis" "citation" "ocr-wrapper")

# Validation functions
validate_chart_structure() {
    local chart_path=$1
    local chart_name=$2

    log_info "Validating chart structure for ${chart_name}..."

    # Check required files (different for umbrella vs service charts)
    if [ "$chart_name" == "contract-analyzer" ]; then
        # Umbrella chart - only needs Chart.yaml and values.yaml
        local required_files=(
            "Chart.yaml"
            "values.yaml"
        )
    else
        # Service chart - needs full template structure
        local required_files=(
            "Chart.yaml"
            "values.yaml"
            "templates/deployment.yaml"
            "templates/service.yaml"
            "templates/serviceaccount.yaml"
            "templates/_helpers.tpl"
        )
    fi

    for file in "${required_files[@]}"; do
        if [ ! -f "${chart_path}/${file}" ]; then
            log_error "Missing required file: ${chart_path}/${file}"
            return 1
        fi
    done

    log_success "Chart structure validation passed for ${chart_name}"
    return 0
}

validate_yaml_syntax() {
    local chart_path=$1
    local chart_name=$2

    log_info "Validating YAML syntax for ${chart_name}..."

    # Check if PyYAML is available
    if ! python3 -c "import yaml" 2>/dev/null; then
        log_warning "PyYAML not available, skipping YAML syntax validation"
        log_info "To install: pip3 install PyYAML"
        return 0
    fi

    # Find all YAML files and validate syntax
    local yaml_files
    yaml_files=$(find "${chart_path}" -name "*.yaml" -o -name "*.yml")

    for file in $yaml_files; do
        # Skip template files with Helm syntax
        if [[ "$file" == *"/templates/"* ]]; then
            continue
        fi

        # Validate YAML syntax using Python
        if ! python3 -c "import yaml; yaml.safe_load(open('$file'))" 2>/dev/null; then
            log_error "Invalid YAML syntax in: $file"
            return 1
        fi
    done

    log_success "YAML syntax validation passed for ${chart_name}"
    return 0
}

validate_chart_metadata() {
    local chart_path=$1
    local chart_name=$2
    
    log_info "Validating chart metadata for ${chart_name}..."
    
    local chart_file="${chart_path}/Chart.yaml"
    
    # Check required fields in Chart.yaml
    local required_fields=("apiVersion" "name" "description" "type" "version" "appVersion")
    
    for field in "${required_fields[@]}"; do
        if ! grep -q "^${field}:" "$chart_file"; then
            log_error "Missing required field '${field}' in ${chart_file}"
            return 1
        fi
    done
    
    # Validate chart name matches directory
    local chart_name_in_file
    chart_name_in_file=$(grep "^name:" "$chart_file" | cut -d' ' -f2)
    if [ "$chart_name_in_file" != "$chart_name" ]; then
        log_error "Chart name mismatch: directory=${chart_name}, Chart.yaml=${chart_name_in_file}"
        return 1
    fi
    
    log_success "Chart metadata validation passed for ${chart_name}"
    return 0
}

validate_values_structure() {
    local chart_path=$1
    local chart_name=$2

    log_info "Validating values structure for ${chart_name}..."

    local values_file="${chart_path}/values.yaml"

    if [ "$chart_name" == "contract-analyzer" ]; then
        # Umbrella chart - check for global and service configurations
        local required_keys=("global")

        for key in "${required_keys[@]}"; do
            if ! grep -q "^${key}:" "$values_file"; then
                log_error "Missing required key '${key}' in ${values_file}"
                return 1
            fi
        done

        # Check that service configurations exist
        for service in "${SERVICES[@]}"; do
            if ! grep -q "^${service}:" "$values_file"; then
                log_error "Missing service configuration '${service}' in ${values_file}"
                return 1
            fi
        done
    else
        # Service chart - check for standard service keys
        local required_keys=("replicaCount" "image" "service" "resources" "autoscaling")

        for key in "${required_keys[@]}"; do
            if ! grep -q "^${key}:" "$values_file"; then
                log_error "Missing required key '${key}' in ${values_file}"
                return 1
            fi
        done
    fi

    log_success "Values structure validation passed for ${chart_name}"
    return 0
}

validate_template_syntax() {
    local chart_path=$1
    local chart_name=$2
    
    log_info "Validating template syntax for ${chart_name}..."
    
    # Check for common template issues
    local template_files
    template_files=$(find "${chart_path}/templates" -name "*.yaml" 2>/dev/null || true)
    
    for file in $template_files; do
        # Check for unclosed template blocks
        if grep -q "{{-.*[^}]$" "$file"; then
            log_warning "Potential unclosed template block in: $file"
        fi
        
        # Check for missing spaces in template functions
        if grep -q "{{[^[:space:]]" "$file" || grep -q "[^[:space:]]}}" "$file"; then
            log_warning "Template functions should have spaces: $file"
        fi
    done
    
    log_success "Template syntax validation passed for ${chart_name}"
    return 0
}

# Main validation function
validate_chart() {
    local chart_path=$1
    local chart_name=$2
    
    echo ""
    log_info "=== Validating ${chart_name} chart ==="
    
    if [ ! -d "$chart_path" ]; then
        log_error "Chart directory not found: $chart_path"
        return 1
    fi
    
    # Run all validations
    validate_chart_structure "$chart_path" "$chart_name" || return 1
    validate_yaml_syntax "$chart_path" "$chart_name" || return 1
    validate_chart_metadata "$chart_path" "$chart_name" || return 1
    validate_values_structure "$chart_path" "$chart_name" || return 1
    validate_template_syntax "$chart_path" "$chart_name" || return 1
    
    log_success "All validations passed for ${chart_name}"
    return 0
}

# Main execution
main() {
    log_info "🔍 Starting Helm chart validation for ContractAnalyzer..."
    
    # Check if we're in the right directory
    if [ ! -d "$CHART_DIR" ]; then
        log_error "Chart directory not found: $CHART_DIR"
        log_error "Please run this script from the project root directory"
        exit 1
    fi
    
    # Validate umbrella chart
    validate_chart "$CHART_DIR" "contract-analyzer" || exit 1
    
    # Validate sub-charts
    local failed_charts=()
    for service in "${SERVICES[@]}"; do
        local service_chart_path="${CHART_DIR}/charts/${service}"
        if ! validate_chart "$service_chart_path" "$service"; then
            failed_charts+=("$service")
        fi
    done
    
    # Summary
    echo ""
    log_info "=== Validation Summary ==="
    
    if [ ${#failed_charts[@]} -eq 0 ]; then
        log_success "🎉 All Helm charts passed validation!"
        echo ""
        log_info "Charts validated:"
        echo "  • contract-analyzer (umbrella chart)"
        for service in "${SERVICES[@]}"; do
            echo "  • $service"
        done
        echo ""
        log_info "Next steps:"
        echo "  • Test deployment: ./scripts/k3d_bootstrap.sh"
        echo "  • Manual install: cd deploy && make install"
        echo "  • Lint with Helm: cd deploy && make lint"
    else
        log_error "❌ Validation failed for the following charts:"
        for chart in "${failed_charts[@]}"; do
            echo "  • $chart"
        done
        exit 1
    fi
}

# Run main function
main "$@"
