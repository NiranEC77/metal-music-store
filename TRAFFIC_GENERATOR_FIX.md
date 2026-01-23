# Traffic Generator Chrome/Selenium Fix

## Problem
The traffic generator was experiencing Chrome session errors in Kubernetes with the message:
```
Message: session not created: DevToolsActivePort file doesn't exist
```

This error occurs when Chrome cannot create its debugging port file, which is common in containerized environments.

## Root Causes
1. **Missing remote debugging port** - Chrome needs an explicit debugging port in containers
2. **Process spawning issues** - Chrome's multi-process architecture can fail in restricted environments
3. **Insufficient permissions** - Non-root users need proper directory permissions for Chrome's temp files

## Solution Applied

### 1. Chrome Options (app.py)
Added critical flags to the Chrome WebDriver configuration:

```python
# Critical fix for DevToolsActivePort error in containers
chrome_options.add_argument('--remote-debugging-port=9222')
chrome_options.add_argument('--single-process')  # Run in single process mode
```

**Why this works:**
- `--remote-debugging-port=9222`: Explicitly tells Chrome where to create the DevTools port file
- `--single-process`: Prevents Chrome from spawning multiple processes, which can fail in containers with security restrictions

### 2. Dockerfile Improvements
Updated the Dockerfile to create necessary directories with proper permissions:

```dockerfile
# Create non-root user and necessary directories
RUN useradd -m -u 1000 appuser \
    && mkdir -p /tmp/.X11-unix /tmp \
    && chmod 1777 /tmp /tmp/.X11-unix \
    && chown -R appuser:appuser /app
```

**Why this works:**
- Creates `/tmp/.X11-unix` directory that Chrome may need for display operations
- Sets proper permissions (1777) on `/tmp` for the non-root user
- Ensures the appuser has write access to necessary directories

### 3. Kubernetes Configuration (Already Present)
The deployment already had the correct `/dev/shm` volume mount:

```yaml
volumeMounts:
- name: dshm
  mountPath: /dev/shm
volumes:
- name: dshm
  emptyDir:
    medium: Memory
    sizeLimit: 2Gi
```

This is essential because Chrome uses shared memory extensively.

## Deployment

The fix has been committed and pushed to the main branch. The GitHub Actions workflow will:
1. Auto-increment the version
2. Build the new Docker image
3. Push to GHCR (GitHub Container Registry)
4. Update the Kubernetes deployment YAML with the new version

### To Deploy the Fix

Once the GitHub Actions workflow completes:

```bash
# Apply the updated deployment
kubectl apply -f k8s-traffic-generator-deployment.yaml

# Watch the rollout
kubectl rollout status deployment/traffic-generator

# Check the logs to verify Chrome starts successfully
kubectl logs -f deployment/traffic-generator
```

## Verification

After deployment, you should see:
- ✅ No more "DevToolsActivePort file doesn't exist" errors
- ✅ Chrome sessions starting successfully
- ✅ User journeys completing (browse, shopping, order, admin)
- ✅ Traffic statistics being collected

## Additional Notes

The traffic generator now runs Chrome in a more container-friendly mode:
- Single process mode reduces resource overhead
- Explicit debugging port prevents file creation issues
- Proper permissions ensure non-root execution works correctly

All existing Chrome flags for headless operation, security, and performance optimization remain in place.

## Update: Session Stability Improvements

### Problem: Invalid Session ID Errors
After the initial fix, Chrome was starting successfully but crashing during long-running sessions with:
```
Message: invalid session id
```

This occurs because:
- Chrome can crash or run out of memory during extended use
- The `--single-process` flag, while fixing the initial issue, caused instability
- Long-running browser sessions accumulate memory leaks

### Solution: Automatic Session Recreation

Added intelligent session management:

```python
def is_session_valid(driver):
    """Check if the WebDriver session is still valid"""
    try:
        _ = driver.current_url
        return True
    except Exception:
        return False
```

**Key improvements:**
1. **Session validation** - Check if the driver is still valid before each journey
2. **Automatic recreation** - Recreate the driver when it becomes invalid
3. **Proactive refresh** - Recreate driver every 10 journeys to prevent memory leaks
4. **Better error handling** - Catch session errors and recreate instead of failing
5. **Removed `--single-process`** - This flag caused more problems than it solved

**How it works:**
- Before each journey, check if the session is valid
- If invalid or after 10 journeys, cleanly quit and create a new driver
- If a journey fails with a session error, mark driver for recreation
- Continue traffic generation seamlessly without user intervention

This ensures the traffic generator can run indefinitely without manual intervention!
