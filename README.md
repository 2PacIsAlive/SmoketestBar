# SmoketestBar

Simple smoketests using AnyBar (https://github.com/tonsky/AnyBar)

`for i in {1..5}; do ./SmoketestBar.sh example.json 173${i} ${i} &; done`

## Usage

To create a new smoketest, make a new json file with the following structure:
```
{
  "events": [
    {
      "command": "[[THE EVENT COMMAND TO EXECUTE]]"
    }
  ],
  "verification": {
    "path": "[[THE JSON PATH (jq) TO THE VERIFICATION VALUE]]",
    "value": "[[THE EXPECTED VALUE]]",
    "command": "[[THE VERIFICATION COMMAND TO EXECUTE]]"
  }
}
```

Execute a test like so:
`./SmoketestBar.sh [TEST_CASE] [UDP_PORT] [TEST_INTERVAL_SECONDS]`

For example:
`./SmoketestBar.sh example.json 1738 3`

You can run several tests at once, but only one test per udp port.

Add an "&" to your command to run the test in the background. 
SmoketestBar will take care of shutting down the test when you quit the AnyBar instance. 

# Note: If you aren't on a mac, or don't want to install AnyBar, test status will be printed to the console.  
