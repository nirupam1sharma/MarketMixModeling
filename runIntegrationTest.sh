env=$1
if [$env -eq '']; then
	env='dev'
fi
cd ./optimization-integration-test && ./gradlew sanityCucumber -Denv=$env && cd ..
