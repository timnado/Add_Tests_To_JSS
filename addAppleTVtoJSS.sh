#!/bin/sh
#
# THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
# PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE
# FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
# OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
# DEALINGS IN THE SOFTWARE.
#
# This script is designed to take a csv of first name and last name pairs and create iPad
# records within the JSS. Please modify variables below and run the script.
#
# CSV should have First Name, Last Name and leave a return at the end of the document
# This script will give you the correct formatting
# echo -e "first,last\nfirst2,last2\nfirst3,last3" >> ~/Desktop/test.csv
#
# Variables

# JSS URL, example https://jss.company.com:8443/
jssURL="https://jss.jamfcloud.com/"
# User Name for API account
apiUser="USS Username"
# Password for API account
apiPass="password"
# Model Name
model="Apple TV"
# Model Identifier
modelIdentifier="AppleTV4,1"

# Don't change anything below this point unless you know what you are doing

	# General Variables
	SN=`echo $(for i in {1..9}; do echo $(( ( RANDOM % 10 ) )); done) | sed -e 's/ //g'`
	UDID=`uuidgen | tr -d - | tr '[:upper:]' '[:lower:]'`
	ipAddress=`echo '10 10 20'$(od -An -N1 -t u4 /dev/urandom) | sed -e 's/ /./g'`
	wifiMAC=`echo '1C'$(od -An -N5 -t xC /dev/urandom) | tr '[:lower:]' '[:upper:]' | sed -e 's/ /:/g'`
	bluetoothMAC=`echo '1C'$(od -An -N5 -t xC /dev/urandom) | tr '[:lower:]' '[:upper:]' | sed -e 's/ /:/g'`
	battery=`echo $(for i in {1..2}; do echo $(( ( RANDOM % 10 ) )); done) | sed -e 's/ //g'`

	# Location Variables
	firstNameLower=`echo $firstName | tr '[:upper:]' '[:lower:]'`
	lastNameLower=`echo $lastName | tr '[:upper:]' '[:lower:]'`

	curl -sS -k -i -u $apiUser:$apiPass -X POST -H "Content-Type: text/xml" -d "<?xml version=\"1.0\" encoding=\"ISO-8859-1\"?>
		<mobile_device>
			<general>
				<device_name>Apple TV</device_name>
				<serial_number>DNP$SN</serial_number>
				<udid>$UDID</udid>
				<wifi_mac_address>$wifiMAC</wifi_mac_address>
				<bluetooth_mac_address>$bluetoothMAC</bluetooth_mac_address>
				<model>$model</model>
				<model_identifier>$modelIdentifier</model_identifier>
				<model_display>$model</model_display>
				<device_ownership_level>Institutional</device_ownership_level>
				<managed>true</managed>
				<supervised>True</supervised>
				<battery_level>$battery</battery_level>
			</general>
		</mobile_device>" "$jssURL"JSSResource/mobiledevices/id/0
