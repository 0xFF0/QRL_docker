@echo off
SET BOOTSTRAP=false
SET QRL_DATA_DIR=%~dp0qrlData
SET BOOTSTRAP_DEST=%QRL_DATA_DIR%\data
SET BOOTSTRAP_URL=https://cdn.qrl.co.in/mainnet/QRL_Mainnet_State.tar.gz
SET BOOTSTRAP_URL_CHECKSUM=https://cdn.qrl.co.in/mainnet/Mainnet_State_Checksums.txt


:: Create qrlData folder
if not exist %BOOTSTRAP_DEST%\ (
  mkdir %BOOTSTRAP_DEST%
)

:: Bootstrap parameter
IF NOT "%1"=="" (
    IF "%1"=="--bootstrap" (
        SET BOOTSTRAP=true
    )
)


:: Bootstrap
if "%BOOTSTRAP%" == "true" (
    curl -L %BOOTSTRAP_URL_CHECKSUM% --output Mainnet_State_Checksums.txt 
	curl -L %BOOTSTRAP_URL% --output QRL_Mainnet_State.tar.gz
	tar -xzf QRL_Mainnet_State.tar.gz -C %BOOTSTRAP_DEST%
)


:: QRL node configuration
echo public_api_host: '0.0.0.0' > %QRL_DATA_DIR%\config.yml
echo mining_api_enabled: True >> %QRL_DATA_DIR%\config.yml
echo mining_api_host: '0.0.0.0' >> %QRL_DATA_DIR%\config.yml


:: Start qrl node with Grafana and portainer
docker-compose -f docker-compose-qrl.yaml up -d