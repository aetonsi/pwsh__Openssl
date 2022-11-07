# pwsh__Openssl
Powershell tools to encrypt and decrypt files with OpenSSL.

Uses `aes-256-cbc` with 1 million iterations.

# Usage
```powershell
# First import the module
Import-Module ./Openssl.psm1

# Then you can use its functions...

# set/get encryption password
$pass = Read-Host -MaskInput "Enter password"

# Encrypt a file
$pass | ConvertTo-OpensslEncrypted -in ./plaintext.txt -out ./encrypted.dat
# or with base64 encoding
$pass | ConvertTo-OpensslEncrypted -in ./plaintext.txt -out ./encrypted.base64.txt -base64
# or with output to console instead of file
$pass | ConvertTo-OpensslEncrypted -in ./plaintext.txt -base64

# Decrypt a file
$pass | ConvertFrom-OpensslEncrypted -in ./encrypted.dat -out ./plaintext.txt
# or, if the file was base64 encoded
$pass | ConvertFrom-OpensslEncrypted -in ./encrypted.base64.txt -out ./plaintext.txt -base64
# or with output to console instead of file
$pass | ConvertFrom-OpensslEncrypted -in ./encrypted.base64.txt -base64

# Decrypt a file and read a single line (eg. the 4th line) as UTF8
$pass | Read-OpensslEncryptedFileLineAsUtf8 -in ./encrypted.dat -line 4
# or, if the file was base64 encoded
$pass | Read-OpensslEncryptedFileLineAsUtf8 -in ./encrypted.base64.txt -line 4 -base64
# or with output to a file
$pass | Read-OpensslEncryptedFileLineAsUtf8 -in ./encrypted.base64.txt -out ./line.txt -line 4 -base64

# Run openssl speed
Invoke-OpensslSpeed -in ./encrypted.dat
# or, if the file was base64 encoded
Invoke-OpensslSpeed -in ./encrypted.base64.txt -base64
# or, altering the test duration
Invoke-OpensslSpeed -in ./encrypted.base64.txt -base64 -seconds 10

# (helper function) Calculate the filesize of the plaintext of a base64 encoded file
Get-Base64EncodedFilePlaintextSize -in ./encrypted.base64.txt

```
