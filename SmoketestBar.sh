#!/bin/bash

PID=$$;

TESTING="blue";
SUCCESS="green";
FAILURE="red";

function usage { echo "USAGE: ./SmoketestBar.sh [TEST_CASE] [UDP_PORT] [TEST_INTERVAL_SECONDS]"; }
function example { echo "EXAMPLE: ./SmoketestBar.sh example.json 1739 3"; }

TEST_CASE="$1";
UDP_PORT="$2";
TEST_INTERVAL_SECONDS="$3";
if [[ -z ${TEST_CASE} || -z ${UDP_PORT} || -z ${TEST_INTERVAL_SECONDS} ]]; then
	echo "ERROR: Please specify a test case, an open UDP port, and an interval at which to execute the test"; 
	usage; example; exit 1; fi

function tryToInstallBrew {
	echo "Homebrew (https://brew.sh/) is required. Would you like to install it? (y/n): "; read should_install_brew;
	if [[ "${should_install_brew}" ]]; then 
		/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)";
		BREW_INSTALLED=true; fi
}

function tryToInstallAnyBar {
	echo "AnyBar (https://github.com/tonsky/AnyBar) is required. Would you like to install it? (y/n):"; read should_install_anybar;
	if [[ "${should_install_anybar}" == "y" ]]; then 
		BREW_INSTALLED=`which brew`;
		if [[ ${BREW_INSTALLED} ]]; then 
			brew cask install anybar; 
		else tryToInstallBrew; 
			if [[ ${BREW_INSTALLED} ]]; then 
				brew cask install anybar; 
				ANYBAR_INSTALLED=true; fi;
		fi; 
	fi;
}

function anybar { echo -n $1 | nc -4u -w0 localhost ${2:-1738}; }

function startAnyBarInstance {
	ANYBAR_PORT=${UDP_PORT} open -na AnyBar;
	echo "AnyBar instance started on port ${UDP_PORT}..."
}

function shutdownTestIfAnyBarQuit {
	if [[ `lsof -i udp:${UDP_PORT}` ]]; then running=true;
	else echo "Stopping test..."; exit 1; fi
}

function setStatus {
	STATUS="$1";	
	if [[ ${ANYBAR_INSTALLED} ]]; then 
		anybar ${STATUS} ${UDP_PORT};
	else echo "${TEST_CASE} status: ${STATUS}"; fi	
}

function loadTestCase {
	test_case_json=$(cat $TEST_CASE); 
	
	EVENT=$(jq -r '.events[0]' <<< "${test_case_json}"); # TODO: support more than one event
	EXPECTED=$(jq -r '.verification' <<< "${test_case_json}");
	
	EVENT_COMMAND=$(jq -r '.command' <<< "${EVENT}"); # TODO: support more than one event
	VERIFICATION_PATH=$(jq -r '.path' <<< "${EXPECTED}");	
	VERIFICATION_VALUE=$(jq -r '.value' <<< "${EXPECTED}");
	VERIFICATION_COMMAND=$(jq -r '.command' <<< "${EXPECTED}");	
}

function execCommand {
	COMMAND=$@; RESULT=$(eval ${COMMAND}); 
}

function verify {
	execCommand ${VERIFICATION_COMMAND};
	RESULT_VALUE=$(jq -r ${VERIFICATION_PATH} <<< "${RESULT}");
	if [[ ${VERIFICATION_VALUE} == ${RESULT_VALUE} ]]; then
		VERIFIED=true;
	else unset VERIFIED; fi;
}

function runTest {
	if [[ `lsof -i udp:${UDP_PORT}` ]]; then
		echo "ERROR: There is already a test running on port ${UDP_PORT}"; exit 1; 
	else startAnyBarInstance; fi
	loadTestCase; 
	while true; do
		shutdownTestIfAnyBarQuit;
		setStatus ${TESTING};
		execCommand ${EVENT_COMMAND};
		verify;
		if [[ ${VERIFIED} ]]; then
			setStatus ${SUCCESS};
		else setStatus ${FAILURE}; fi
		sleep ${TEST_INTERVAL_SECONDS};
	done;	
}

# Install AnyBar (https://github.com/tonsky/AnyBar) if not installed
type /Applications/AnyBar.app/Contents/MacOS/AnyBar >/dev/null 2>&1 && ANYBAR_INSTALLED=true || \
	{ tryToInstallAnyBar;}

echo "Running test...";
runTest;
