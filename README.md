# Enhanced Bug Bounty Automation Tool

A modular and robust bug bounty automation toolkit for reconnaissance, discovery, and vulnerability scanning. Supports both single-target and batch scanning operations with extensive configuration options.

## Features

- Comprehensive subdomain enumeration (passive and active)
- HTTP service probing and analysis
- JavaScript file discovery and analysis
- Vulnerability scanning (LFI, XSS, SQL injection, etc.)
- Modular architecture with error handling
- Configurable settings via config.ini
- Detailed logging system
- Batch scanning capabilities with parallel processing
- Progress tracking and scan resumption
- Setup verification tool

## Installation

### Automatic Installation

The easiest way to install all dependencies is using the provided installation script:

```bash
# Make the script executable
chmod +x install_dependencies.sh

# Run the installation script as root
sudo ./install_dependencies.sh
```

The installation script:
- Detects your operating system (Ubuntu/Debian, RHEL/CentOS, or Arch Linux)
- Installs all required system packages
- Sets up Go and Python environments
- Installs all required and optional tools
- Downloads and configures common wordlists
- Sets up proper permissions and paths

### Manual Installation

If you prefer to install dependencies manually, here are the required components:

#### Required Tools
- subfinder - Subdomain discovery tool
- amass - In-depth subdomain enumeration
- curl - Data transfer tool
- jq - JSON processor
- github-subdomains - GitHub subdomain finder
- assetfinder - Domain discovery tool
- massdns - High-performance DNS resolver
- shuffledns - DNS resolver and subdomain bruteforcer
- dnsx - DNS toolkit
- ffuf - Web fuzzer
- httpx - HTTP probe tool
- gf - Pattern matcher
- qsreplace - Query string replacer
- dalfox - XSS scanner
- paramspider - Parameter discovery
- arjun - HTTP parameter discovery

#### Optional Tools
- cloud_enum - Cloud resource enumeration
- aws CLI - AWS command line interface
- feroxbuster - Content discovery tool
- dirsearch - Web path scanner
- shodan CLI - Shodan search tool
- censys CLI - Censys search tool
- subscraper - Subdomain enumeration
- xnLinkFinder - Link finder
- GitDorker - GitHub dork scanner

### Post-Installation Setup

1. Clone this repository:
   ```bash
   git clone <repository-url>
   cd bug-bounty-automation
   ```

2. Make all scripts executable:
   ```bash
   chmod +x *.sh
   ```

3. Configure settings:
   ```bash
   cp config.ini.example config.ini
   # Edit config.ini with your preferred settings
   ```

4. Verify installation:
   ```bash
   ./test_setup.sh
   ```

## Configuration

### Interactive Setup

The easiest way to create your configuration file is using the interactive setup script:

```bash
./setup_config.sh
```

This script will:
- Guide you through essential configuration options
- Provide sensible defaults for common settings
- Securely handle API tokens and sensitive data
- Create a customized config.ini file
- Backup any existing configuration before modifications

### Manual Configuration

1. Create your configuration file from the template:
   ```bash
   cp config.ini.example config.ini
   ```

2. Edit config.ini to customize your settings:
   ```bash
   nano config.ini  # or use your preferred editor
   ```

### Configuration Options

The configuration file includes several categories of settings:

#### Basic Settings
- `TARGET` - Target domain for scanning
- `OUTPUT_DIR` - Directory for scan results
- `WORDLIST` - Path to subdomain wordlist
- `THREADS` - Number of concurrent threads

#### API Configuration
- `GITHUB_TOKEN` - GitHub API token for repository scanning
- `SHODAN_API_KEY` - Shodan API key for host information
- `CENSYS_API_ID` and `CENSYS_API_SECRET` - Censys API credentials

#### Scanning Parameters
- `HTTP_PORTS` - Ports to scan (e.g., 80,443,8080,8443)
- `RECURSION_DEPTH` - Depth for recursive scanning
- `TIMEOUT` - Request timeout in seconds
- `MAX_RETRIES` - Number of retry attempts

#### Feature Flags
- `ENABLE_SCREENSHOTS` - Enable webpage screenshots
- `ENABLE_JS_ANALYSIS` - Enable JavaScript file analysis
- `ENABLE_CLOUD_ENUM` - Enable cloud resource enumeration
- `ENABLE_VULNERABILITY_SCAN` - Enable vulnerability scanning

#### Batch Scanning
- `PARALLEL_SCANS` - Number of concurrent scans
- `DELAY_BETWEEN_SCANS` - Delay between scans in seconds

#### Advanced Options
- `USER_AGENT` - Custom user agent string
- `PROXY` settings for HTTP/SOCKS proxies
- `SENSITIVE_PATTERNS` for custom pattern matching
- Cloud service provider configurations

For a complete list of options and their descriptions, refer to the comments in `config.ini.example`.

### Configuration Tips

1. **API Tokens**: Keep your API tokens secure and never commit them to version control
2. **Rate Limiting**: Adjust `REQUESTS_PER_SECOND` and `DELAY_BETWEEN_SCANS` to avoid overwhelming targets
3. **Resource Usage**: Modify `THREADS` and `PARALLEL_SCANS` based on your system's capabilities
4. **Scope Control**: Use `IN_SCOPE_PROTOCOLS` and `OUT_OF_SCOPE_DOMAINS` to limit scan scope
5. **Custom Wordlists**: Provide paths to your own wordlists for more targeted scanning

### Verifying Configuration

After setting up your configuration:

1. Run the test setup script to verify settings:
   ```bash
   ./test_setup.sh
   ```

2. Review the configuration check results:
   - Validates file paths and permissions
   - Checks API token formats
   - Verifies tool availability
   - Ensures wordlist accessibility

## Usage

### Quick Start

The toolkit provides a unified interface to access all features:

```bash
./run.sh
```

This launches an interactive menu with the following options:
1. **Manage Targets**
   - Add, edit, or remove targets
   - Validate domains and scope
   - Track program information

2. **Run Single Target Scan**
   - Execute scan on individual domain
   - Real-time progress monitoring
   - Direct result access

3. **Run Batch Scan**
   - Process multiple targets
   - Configure parallel execution
   - Set delays between scans

4. **Generate Reports**
   - Create HTML, JSON, or Markdown reports
   - Customize report content
   - Export in multiple formats

5. **Maintenance**
   - Check tool versions
   - Update dependencies
   - Clean old results

6. **Setup & Configuration**
   - Install required tools
   - Test environment
   - Configure settings

Features:
- User-friendly interface
- Centralized access to all tools
- Guided workflows
- Error handling and validation
- Progress tracking
- Automatic dependency checks

### Initial Setup

Before running scans, verify your installation and configuration:

```bash
./test_setup.sh
```

This will check for:
- Required and optional tool installations
- Configuration file validity
- Wordlist availability
- Script permissions

### Single Target Scanning

Basic usage:
```bash
./bug_bounty.sh <target_domain>
```

Example:
```bash
./bug_bounty.sh example.com
```

### Target Management

The toolkit includes an interactive target management system:

```bash
./target_input.sh [OPTIONS]
```

Options:
```
  -f, --file FILE      Target file to edit (default: targets.txt)
  --no-backup         Don't create backup of existing targets file
  -h, --help          Show this help message
```

Features:
- Interactive target input form
- Domain and scope validation
- Program information tracking
- Target list management
- Automatic backup of target files
- Notes and metadata support

Available operations:
1. Add new targets with:
   - Domain validation
   - Scope definition (supports wildcards)
   - Program name
   - Additional notes
2. List existing targets
3. Edit target information
4. Remove targets
5. Automatic backup before modifications

Example usage:
```bash
# Launch interactive target manager
./target_input.sh

# Use custom targets file
./target_input.sh --file custom_targets.txt

# Skip automatic backup
./target_input.sh --no-backup
```

### Batch Scanning

After setting up your targets using the target manager, run batch scanning:

```bash
./batch_scan.sh [OPTIONS]
```

Batch scanning options:
```
Options:
  -p, --parallel N        Run N scans in parallel (default: 1)
  -d, --delay N          Delay N seconds between scans (default: 0)
  -r, --resume           Resume from last scan position
  -t, --targets FILE     Use specific targets file (default: targets.txt)
  -h, --help            Show this help message
```

Example batch scanning:
```bash
# Run 2 scans in parallel with 30-second delays
./batch_scan.sh --parallel 2 --delay 30

# Resume an interrupted batch scan
./batch_scan.sh --resume

# Use a custom targets file
./batch_scan.sh --targets custom_targets.txt
```

## Results and Reporting

### Output Structure

Results are organized in the output directory (default: `bug_bounty_results/`):

```
bug_bounty_results/
├── subdomains/               # Subdomain enumeration results
│   ├── subfinder_subs.txt   # Subfinder results
│   ├── amass_subs.txt      # Amass results
│   ├── crtsh_subs.txt      # Certificate transparency results
│   └── all_subdomains.txt  # Combined unique subdomains
├── js/                      # JavaScript analysis
│   ├── js_files.txt        # Discovered JS files
│   ├── aws_keys.txt        # Potential AWS keys
│   └── sensitive_urls.txt  # Sensitive endpoints
├── vulns/                   # Vulnerability scan results
│   ├── lfi_results.txt     # Local File Inclusion findings
│   ├── xss_results.txt     # Cross-Site Scripting findings
│   └── sql_injection_results.txt  # SQL Injection findings
└── live_websites.txt        # Active web services

reports/                     # Generated reports directory
├── example.com_20240101_120000.html  # HTML report
├── example.com_20240101_120000.json  # JSON report
└── example.com_20240101_120000.md    # Markdown report
```

### Report Generation

Generate formatted reports from scan results using the report generation script:

```bash
./generate_report.sh [OPTIONS]
```

Available options:
```
  -d, --directory DIR    Source directory containing scan results
  -o, --output DIR      Output directory for reports (default: reports)
  -f, --format FORMAT   Report format: html,json,md (default: html)
  -t, --target DOMAIN   Target domain for the report
  -h, --help           Show this help message
```

Example usage:
```bash
# Generate HTML and JSON reports for example.com
./generate_report.sh --target example.com --format html,json

# Generate all format reports with custom directories
./generate_report.sh \
  --directory custom_results \
  --output custom_reports \
  --format html,json,md \
  --target example.com
```

### Report Formats

1. **HTML Report**
   - Professional, styled presentation
   - Interactive elements for better readability
   - Easy to share with stakeholders
   - Includes statistics and visual elements

2. **JSON Report**
   - Machine-readable format
   - Suitable for programmatic analysis
   - Can be imported into other tools
   - Complete scan data in structured format

3. **Markdown Report**
   - Clean, text-based format
   - Perfect for GitHub/GitLab documentation
   - Easy to version control
   - Can be converted to other formats

### Report Contents

Each report includes:
- Scan information (target, date, duration)
- Statistics summary
- Discovered subdomains
- Vulnerability findings
- JavaScript analysis results
- Active endpoints
- Screenshots (if enabled)

## Logging

### Main Script Logging
- All operations are logged to `bug_bounty.log`
- Includes timestamps and severity levels
- Helps in troubleshooting and audit trails

### Batch Scanning Logs
- Batch operations logged to `batch_logs/batch_scan.log`
- Individual target logs stored in `batch_logs/<target>_<timestamp>.log`
- Progress tracking in `.scan_progress` for resume capability

## Maintenance and Utilities

### Tool Version Management

Check and manage tool versions using the version checker:

```bash
./check_tools.sh [OPTIONS]
```

Options:
```
  -c, --check-only      Only check versions without installing
  -f, --force-update    Force update all tools
  -s, --skip-install    Skip installation of missing tools
  -h, --help           Show this help message
```

Features:
- Detects installed tools and their versions
- Identifies missing required dependencies
- Provides option to install only missing tools
- Supports forced updates of existing tools
- Checks both core and optional dependencies

Example usage:
```bash
# Check all tool versions without installing
./check_tools.sh --check-only

# Update all tools to latest versions
./check_tools.sh --force-update

# Check versions and install only missing tools
./check_tools.sh
```

### Cleanup Utility

Manage scan results and reports using the cleanup utility:

```bash
./cleanup.sh [OPTIONS]
```

Options:
```
  -d, --days N          Remove files older than N days (default: 30)
  -r, --results-dir DIR Results directory to clean
  -o, --reports-dir DIR Reports directory to clean
  --dry-run            Show what would be deleted without actually deleting
  -h, --help           Show this help message
```

Features:
- Automated cleanup of old scan results
- Configurable retention period
- Separate management of results and reports
- Dry-run mode for safe verification
- Size-based reporting of cleaned data

Example usage:
```bash
# Preview files to be deleted (dry run)
./cleanup.sh --days 7 --dry-run

# Clean files older than 14 days
./cleanup.sh --days 14

# Clean specific directories
./cleanup.sh --results-dir custom_results --reports-dir custom_reports
```

## Error Handling

The toolkit includes robust error handling across all components:
- Dependency checking and version verification
- Input validation and sanitization
- Command execution monitoring
- Graceful failure handling
- Detailed logging of errors
- Recovery mechanisms for interrupted operations

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a new Pull Request

### Development Guidelines
- Run `test_setup.sh` before submitting pull requests
- Use `check_tools.sh` to verify dependency compatibility
- Ensure batch scanning compatibility when modifying core functionality
- Update documentation for any new features or changes
- Follow the existing code style and error handling patterns
- Add appropriate logging for new functionality

## Security Considerations

- Always obtain proper authorization before testing
- Review and customize wordlists for your needs
- Monitor system resource usage
- Be mindful of rate limiting
- Regularly update tools using `check_tools.sh`
- Clean up sensitive data using `cleanup.sh`
- Use secure storage for API keys and tokens

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Thanks to the bug bounty community
- Built upon various open-source security tools
- Inspired by common bug bounty workflows

## Disclaimer

This tool is for educational purposes and authorized testing only. Users are responsible for obtaining proper authorization before conducting security tests.
