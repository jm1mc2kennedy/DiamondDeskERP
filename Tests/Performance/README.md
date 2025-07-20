# Performance Testing Infrastructure

## Overview
This directory contains the Performance Testing infrastructure for DiamondDeskERP iOS application, implementing the Performance Baseline Establishment requirements from the buildout plan.

## Components

### PerformanceBaseline.swift
- Establishes performance baseline through 5-sample device metric validation
- Measures key performance indicators against buildout plan targets:
  - App Launch Time: ≤ 2.0 seconds
  - View Transition Time: ≤ 0.3 seconds
  - CloudKit Sync Time: ≤ 1.5 seconds
  - Memory Usage: ≤ 100MB
  - CPU Usage: ≤ 20%
  - Battery Drain: ≤ 5% per hour
- Persists baseline JSON artifact for regression detection
- Validates against targets and reports success/failure

### PerformanceRegressionTests.swift
- Detects performance regressions against established baseline
- Uses 15% variance tolerance for regression detection
- Generates detailed regression reports with metrics comparison
- Saves timestamped regression reports for analysis
- Fails tests when significant regression is detected

## Usage

### Establishing Baseline
```bash
# Run performance baseline establishment
xcodebuild test -scheme DiamondDeskERP -destination 'platform=iOS Simulator,name=iPhone 15 Pro' -only-testing:DiamondDeskERPTests/PerformanceBaseline/testEstablishPerformanceBaseline
```

### Running Regression Tests
```bash
# Run performance regression detection
xcodebuild test -scheme DiamondDeskERP -destination 'platform=iOS Simulator,name=iPhone 15 Pro' -only-testing:DiamondDeskERPTests/PerformanceRegressionTests/testPerformanceRegression
```

## Output Files

### performance_baseline.json
Located in Documents directory, contains:
- Device information (model, OS version, memory, processor count)
- 5 performance samples with individual measurements
- Calculated averages across all samples
- Validation results against targets
- Timestamp and metadata

### Regression Reports
Located in Documents/PerformanceReports/, contains:
- Timestamped regression analysis reports
- Current vs baseline metrics comparison
- Regression percentages for each metric
- List of failed metrics exceeding tolerance
- Detailed logging output

## CI Integration

### Build Phase Integration
Add to Xcode build phases or CI pipeline:
```bash
# Performance validation in CI
if [ "$CONFIGURATION" = "Release" ]; then
    echo "Running performance baseline validation..."
    xcodebuild test -scheme DiamondDeskERP -destination 'platform=iOS Simulator,name=iPhone 15 Pro' -only-testing:DiamondDeskERPTests/PerformanceRegressionTests/testPerformanceRegression
fi
```

### Performance Gates
- Baseline establishment required before production builds
- Regression tests must pass before merge to main branch
- Performance reports archived for trend analysis
- Alerts on regression threshold breaches

## Real Device Testing

For production validation, run on physical devices:
```bash
# iPhone 15 Pro
xcodebuild test -scheme DiamondDeskERP -destination 'platform=iOS,name=Your iPhone' -only-testing:DiamondDeskERPTests/PerformanceBaseline

# iPad Air
xcodebuild test -scheme DiamondDeskERP -destination 'platform=iOS,name=Your iPad' -only-testing:DiamondDeskERPTests/PerformanceBaseline
```

## Maintenance

### Baseline Updates
- Re-establish baseline after major performance optimizations
- Update targets if requirements change
- Archive old baselines for historical comparison

### Monitoring
- Review regression reports regularly
- Track performance trends over time
- Investigate performance anomalies
- Update tolerance thresholds as needed

## Next Steps

After establishing performance baseline:
1. ✅ Performance Baseline Establishment - COMPLETED
2. 🔄 Accessibility Automation (Priority P1)
3. 🔄 Conflict Logging Implementation (Priority P1)
4. 🔄 Localization Validation (Priority P2)
5. 🔄 Analytics Consent Screen (Priority P2)
6. 🔄 Event QA Console (Priority P2)
