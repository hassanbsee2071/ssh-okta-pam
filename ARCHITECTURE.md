# PAM SSO Login Architecture

## System Overview

This is a PAM (Pluggable Authentication Modules) based Single Sign-On (SSO) solution that integrates Okta OAuth2 Device Flow authentication with SSH access on Linux systems.

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                                    CLIENT SIDE                                 │
├─────────────────────────────────────────────────────────────────────────────────┤
│                                                                                 │
│  ┌─────────────────┐    ┌──────────────────┐    ┌─────────────────────────────┐ │
│  │   End User      │    │  sso-login.sh    │    │     Web Browser            │ │
│  │                 │    │                  │    │                             │ │
│  │ • Runs sso-login│───▶│ • Validates email│───▶│ • Opens Okta auth URL      │ │
│  │ • Enters email  │    │ • Stores in ~/.sso│   │ • User completes auth      │ │
│  │ • Gets password │    │ • Connects to SSH│   │ • Returns to terminal      │ │
│  └─────────────────┘    └──────────────────┘    └─────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────────────┘
                                        │
                                        │ SSH Connection
                                        ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│                                   SERVER SIDE                                  │
├─────────────────────────────────────────────────────────────────────────────────┤
│                                                                                 │
│  ┌─────────────────┐    ┌──────────────────┐    ┌─────────────────────────────┐ │
│  │   SSH Server    │    │   PAM Stack      │    │   Okta OAuth2 Service      │ │
│  │                 │    │                  │    │                             │ │
│  │ • Receives SSH  │───▶│ • deviceflow.so  │───▶│ • Device Authorization    │ │
│  │   connection    │    │ • pam_unix.so    │    │ • Token Exchange           │ │
│  │ • Uses PAM      │    │ • pam_exec.so    │    │ • JWT Token Generation     │ │
│  │   for auth      │    │                  │    │                             │ │
│  └─────────────────┘    └──────────────────┘    └─────────────────────────────┘ │
│                                        │                                        │
│                                        ▼                                        │
│  ┌─────────────────────────────────────────────────────────────────────────────┐ │
│  │                    User Management & Session Creation                       │ │
│  │                                                                             │ │
│  │  ┌─────────────────┐    ┌──────────────────┐    ┌─────────────────────────┐ │ │
│  │  │ pam-okta-create-│    │   User Creation  │    │   Password Generation   │ │ │
│  │  │ user.sh         │    │                  │    │                         │ │ │
│  │  │                 │    │ • Validates JWT  │    │ • Creates temp password │ │ │
│  │  │ • Parses JWT    │───▶│ • Extracts email │───▶│ • Stores in /home/user/ │ │ │
│  │  │ • Checks groups │    │ • Creates user   │    │   password.txt          │ │ │
│  │  │ • Sets sudo     │    │ • Sets permissions│   │ • Sets secure perms     │ │ │
│  │  └─────────────────┘    └──────────────────┘    └─────────────────────────┘ │ │
│  └─────────────────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────────────┘
```

## Component Analysis

### 1. Client-Side Components

#### `sso-login.sh` (End User Script)
- **Purpose**: Main client interface for SSO authentication
- **Key Features**:
  - Email validation (syed.com domain only)
  - Stores email in `~/.sso/okta-email.txt`
  - Connects to SSH server and retrieves Okta URL
  - Automatically opens browser for Okta authentication
  - Displays temporary password to user

#### Email Validation
- Regex: `^[a-z0-9._%+-]+@syed.com$`
- Only allows lowercase syed.com email addresses
- Stores validated email for future use

### 2. Server-Side Components

#### SSH Configuration (`sshd_config`)
- **Authentication Methods**: `any` (allows multiple auth methods)
- **PAM Integration**: `UsePAM yes`
- **Password Authentication**: Enabled
- **Challenge Response**: Enabled

#### PAM Configuration (`sshd`)
- **Authentication Stack**:
  1. `pam_unix.so` (sufficient) - Standard Unix authentication
  2. `deviceflow.so` (sufficient) - Custom Okta device flow
- **Account Management**:
  - `pam_exec.so` - Executes user creation script
  - `pam_nologin.so` - Handles nologin restrictions

#### Custom PAM Module (`deviceflow.c`)
- **Purpose**: Implements OAuth2 Device Flow authentication
- **Key Features**:
  - Initiates device authorization with Okta
  - Generates QR code for mobile authentication
  - Polls for token completion
  - Parses JWT tokens to extract user information
  - Stores tokens in `/tmp/{username}` for user creation

#### User Management (`pam-okta-create-user.sh`)
- **Purpose**: Creates users based on Okta authentication
- **Key Features**:
  - Validates JWT token from `/tmp/{username}`
  - Extracts email and group information
  - Creates user accounts with appropriate permissions
  - Generates temporary passwords
  - Handles sudo group assignment based on Okta groups

#### Cleanup Script (`users-clean-up.sh`)
- **Purpose**: Removes inactive users
- **Key Features**:
  - Identifies non-system users
  - Removes users not in sudo group
  - Cleans up home directories

## Authentication Flow

### 1. Initial Setup
1. User runs `sso-login` command
2. Script validates email format
3. Stores email in local configuration

### 2. Authentication Process
1. User connects to SSH server
2. PAM stack processes authentication
3. `deviceflow.so` initiates OAuth2 device flow
4. Server generates device code and user code
5. QR code and URL displayed to user
6. User authenticates via browser with Okta
7. Server polls for token completion
8. JWT token received and parsed

### 3. User Creation
1. `pam-okta-create-user.sh` executes
2. JWT token validated and parsed
3. User account created if not exists
4. Sudo permissions assigned based on Okta groups
5. Temporary password generated and stored
6. User receives password for SSH access

## Security Features

### Token Management
- JWT tokens stored in `/tmp/{username}` with 600 permissions
- Tokens contain user identity and group information
- Base64 decoding for payload extraction

### User Permissions
- Automatic sudo group assignment for admin users
- Secure home directory creation
- Temporary password generation using MD5 hash

### Email Validation
- Strict domain validation (syed.com only)
- Case-insensitive username extraction
- Persistent email storage for reuse

## Integration Points

### Okta Configuration
- **Client ID**: `zzxxcccwweerrtttt`
- **Authorization URL**: `https://sso.syed.com/oauth2/v1/device/authorize`
- **Token URL**: `https://sso.syed.com/oauth2/v1/token`
- **Scopes**: `openid profile offline_access groups`

### System Dependencies
- **Curl**: HTTP requests to Okta
- **OpenSSL**: JWT token decoding
- **jq**: JSON parsing
- **PAM**: Authentication framework
- **SSH**: Remote access protocol

## File Structure
```
pam-sso-login/
├── end-user-script/
│   └── sso-login.sh          # Client-side authentication script
├── ssh-pam-module/
│   ├── deviceflow.c          # Custom PAM module (C)
│   ├── pam-okta-create-user.sh # User creation script
│   └── users-clean-up.sh     # User cleanup script
├── server-configurations/
│   ├── sshd                  # PAM configuration
│   └── sshd_config           # SSH server configuration
└── images/
    ├── generate-token.png    # GitHub token generation guide
    └── okta.png             # Okta authentication guide
```

## Benefits

1. **Single Sign-On**: Users authenticate once with Okta
2. **Automatic User Provisioning**: Users created automatically on first login
3. **Group-Based Access Control**: Sudo permissions based on Okta groups
4. **Secure Token Handling**: JWT tokens with proper permissions
5. **Mobile-Friendly**: QR code authentication for mobile devices
6. **Centralized Management**: All authentication through Okta
