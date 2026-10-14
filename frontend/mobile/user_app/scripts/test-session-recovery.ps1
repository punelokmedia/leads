$ErrorActionPreference = 'Stop'
Push-Location (Join-Path $PSScriptRoot '..')
try {
    & flutter.bat test --no-pub test/auth_interceptor_test.dart test/session_recovery_test.dart test/live_store_test.dart test/widget_test.dart
    if ($LASTEXITCODE -ne 0) { throw 'Session recovery tests failed. Review the failing test before release.' }
} finally {
    Pop-Location
}
