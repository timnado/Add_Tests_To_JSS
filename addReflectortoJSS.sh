#!/bin/sh
#
# THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
# PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE
# FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
# OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
# DEALINGS IN THE SOFTWARE.
#
# This script is designed to upload info about Reflector running on a computer into the JSS

# Tested with Reflector 2.0.1 and 1.6.6

# Things to do:
	# geting it working with classes

# Variables for CURL commands
	# JSS URL, example https://jss.company.com:8443
		JSS_URL="https://jss.jamfcloud.com"
		if [[ -z $JSS_URL ]]; then
			JSS_URL="$4"
		fi

	# User Name for API account
		API_USERNAME="username"
		if [[ -z $API_USERNAME ]]; then
			API_USERNAME="$5"
		fi

	# Password for API account
		API_PASSWORD="password"
		if [[ -z $API_PASSWORD ]]; then
			API_PASSWORD="$6"
		fi

# Variables for what end users will see
	# Title of alert box
		JAMF_HELPER_TITLE="Self Service Alert"

	# Location for icon for alert box
		JAMF_HELPER_ICON="/Applications/Self Service.app/Contents/Resources/Self Service.icns"

	# Two Versions Chooser
		TWO_VERSIONS_HEADING="Two Versions of Reflector Detected"
		TWO_VERSIONS_DESCRIPTION="We have detected two versions of Reflector on your computer. In order to get the correct name and password for Reflector, please choose the version you most frequently use."

	# Reflector Not installed
		NOT_INSTALLED_HEADING="Reflector Not Detected"
		NOT_INSTALLED_DESCRIPTION="We were not able to find a verion of Reflector on your computer. Please verify that Reflector is installed and has been launched at least once. If you believe this message is an error, please contact your IT department."

	# Onscreen Password Error
		ONSCREEN_HEADING="Onscreen Code Enabled"
		ONSCREEN_DESCRIPTION="We have detected that Reflector is set to require an onscreen code. This option is not supported with Casper Focus. Please choose None or Password under Preferences in Reflector."

	# Asking user to accept their keychain to be read
		PASSWORD_HEADING="Keychain Access Required"
		PASSWORD_DESCRIPTION="We have detected that Reflector is set to require a password to connect to Reflector. You will recieve a popup after this that will require you to Allow or Always Allow security to read your Reflector Password. Please do not choose Deny. If you have quesitons, please contact the IT Department"

# Don't change anything below this point unless you know what you are doing
		# Setting Current User
			CURRENT_USER=`ls -la /dev/console | cut -d " " -f 4`

		# Figure out what versions of Reflector are installed
			REFLECTOR_1_PLIST="/Users/$CURRENT_USER/Library/Preferences/com.squirrels.Reflection.plist"
			REFLECTOR_2_PLIST="/Users/$CURRENT_USER/Library/Preferences/com.squirrels.Reflector-2.plist"

			if [[ -f "$REFLECTOR_1_PLIST" ]] && [[ -f "$REFLECTOR_2_PLIST" ]]; then
				# Reflector 1.x will return REFLECTOR_VERSION_INSTALLED=2
				# Reflector 2.x will return REFLECTOR_VERSION_INSTALLED=0
				REFLECTOR_VERSION_INSTALLED=`/Library/Application\ Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper -windowType utility -title "$JAMF_HELPER_ALERT" -heading "$TWO_VERSIONS_HEADING" -description "$TWO_VERSIONS_DESCRIPTION" -icon "$JAMF_HELPER_ICON" -button1 "Reflector 2" -button2 "Reflector 1"`
			elif [[ -f "$REFLECTOR_2_PLIST" ]]; then
				REFLECTOR_VERSION_INSTALLED="0"
			elif [[ -f "$REFLECTOR_1_PLIST" ]]; then
				REFLECTOR_VERSION_INSTALLED="2"
			else
				/Library/Application\ Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper -windowType utility -title "$JAMF_HELPER_ALERT" -heading "$NOT_INSTALLED_HEADING" -description "$NOT_INSTALLED_DESCRIPTION" -icon "$JAMF_HELPER_ICON" -button1 "Ok"
				exit 1
			fi

		# Setting proper variables based on version of Reflector installed
		case $REFLECTOR_VERSION_INSTALLED in
			*2*)
				# Code for Reflector 1.x
				plutil -convert xml1 "$REFLECTOR_1_PLIST"
				DEVICE_NAME=`awk 'c&&!--c;/BonjourName/{c=1}' $REFLECTOR_1_PLIST | sed 's|<[^>]*>||g'`
				CHECK_PASSWORD=`awk 'c&&!--c;/SecurityType/{c=1}' $REFLECTOR_1_PLIST | sed 's|<[^>]*>||g'`
					if [ $CHECK_PASSWORD == 0 ]; then
						echo "No Password Set"
					elif [ $CHECK_PASSWORD == 1 ]; then
						echo "Onscreen Code Selected"
						/Library/Application\ Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper -windowType utility -title "$JAMF_HELPER_ALERT" -heading "$ONSCREEN_HEADING" -description "$ONSCREEN_DESCRIPTION" -icon "$JAMF_HELPER_ICON" -button1 "Ok"
						exit 1
					elif [ $CHECK_PASSWORD == 2 ]; then
						echo "Password Saved in Keychain"
						/Library/Application\ Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper -windowType utility -title "$JAMF_HELPER_ALERT" -heading "$PASSWORD_HEADING" -description "$PASSWORD_DESCRIPTION" -icon "$JAMF_HELPER_ICON" -button1 "Continue"
						AIRPLAY_PASSWORD=`security find-generic-password -wl "com.airsquirrels.Reflector" 2>/dev/null`
					fi
				;;
			*0*)
				# Code for Reflector 2.x
				plutil -convert xml1 "$REFLECTOR_2_PLIST"
				DEVICE_NAME=`awk 'c&&!--c;/BroadcastName/{c=1}' $REFLECTOR_2_PLIST | sed 's|<[^>]*>||g'`
				CHECK_PASSWORD=`awk 'c&&!--c;/PasswordMode/{c=1}' $REFLECTOR_2_PLIST | sed 's|<[^>]*>||g'`
					if [ $CHECK_PASSWORD == 0 ]; then
						echo "No Password Set"
					elif [ $CHECK_PASSWORD == 1 ]; then
						echo "Password Saved in Keychain"
						/Library/Application\ Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper -windowType utility -title "$JAMF_HELPER_ALERT" -heading "$PASSWORD_HEADING" -description "$PASSWORD_DESCRIPTION" -icon "$JAMF_HELPER_ICON" -button1 "Continue"
						AIRPLAY_PASSWORD=`security find-generic-password -wl "com.squirrels.Reflector-2" 2>/dev/null`
					elif [ $CHECK_PASSWORD == 2 ]; then
						echo "Onscreen Code Selected"
						/Library/Application\ Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper -windowType utility -title "$JAMF_HELPER_ALERT" -heading "$ONSCREEN_HEADING" -description "$ONSCREEN_DESCRIPTION" -icon "$JAMF_HELPER_ICON" -button1 "Ok"
						exit 1
					fi
				;;
		esac

		# Setting the time of enrollment
			EPOCH_TIME=`date -u +%s`

		# Using the computer's serial number
			SERIAL_NUMBER=`system_profiler SPHardwareDataType | awk '/Serial/ {print $4}'`

		# Using the computer's UDID/UUID
			UUID=`system_profiler SPHardwareDataType | awk '/UUID/ {print $3}'`

		# Using the computer's EN0 MAC address
			EN0_MAC_ADDRESS=`networksetup -listallhardwareports | awk 'c&&!--c;/en0/{c=1}' | awk '{print $3}'`

		# Using the computer's Bluetooth MAC address
			BLUETOOTH_MAC_ADDRESS=`networksetup -listallhardwareports | awk 'c&&!--c;/Bluetooth PAN/{c=2}' | awk '{print $3}'`

		# Checking to see if there is an existing record to update. Will Post if it is new, Put if it is an update
			CHECK_FOR_RECORD=`curl -w "%{http_code}\n" -s -o /dev/null -k -u $API_USERNAME:$API_PASSWORD $JSS_URL/JSSResource/mobiledevices/udid/$UUID`
			if [[ "$CHECK_FOR_RECORD" == "404" ]]; then
				CURL_COMMAND="POST"
				CURL_OBJECT="id/0"
			else
				CURL_COMMAND="PUT"
				CURL_OBJECT="udid/$UUID"
			fi

		# Curl command with all the filled in data
			curl -ss -k -u $API_USERNAME:$API_PASSWORD -X $CURL_COMMAND -H "Content-Type: text/xml" -d "<?xml version=\"1.0\" encoding=\"ISO-8859-1\"?>
				<mobile_device>
				  <general>
				    <display_name>$DEVICE_NAME</display_name>
				    <device_name>$DEVICE_NAME</device_name>
				    <name>$DEVICE_NAME</name>
				    <asset_tag>Reflector Computer</asset_tag>
				    <last_inventory_update/>
				    <last_inventory_update_epoch>$EPOCH_TIME</last_inventory_update_epoch>
				    <last_inventory_update_utc/>
				    <capacity>0</capacity>
				    <capacity_mb>0</capacity_mb>
				    <available>0</available>
				    <available_mb>0</available_mb>
				    <percentage_used>0</percentage_used>
				    <os_type>iOS</os_type>
				    <os_version>8.2</os_version>
				    <os_build>12D508</os_build>
				    <serial_number>$SERIAL_NUMBER</serial_number>
				    <udid>$UUID</udid>
				    <initial_entry_date_epoch>$EPOCH_TIME</initial_entry_date_epoch>
				    <initial_entry_date_utc/>
				    <phone_number/>
				    <ip_address/>
				    <wifi_mac_address>$EN0_MAC_ADDRESS</wifi_mac_address>
				    <bluetooth_mac_address>$BLUETOOTH_MAC_ADDRESS</bluetooth_mac_address>
				    <modem_firmware/>
				    <model>Apple TV 3rd Generation </model>
				    <model_identifier>AppleTV3,1</model_identifier>
				    <model_display>Apple TV 3rd Generation </model_display>
				    <device_ownership_level>Institutional</device_ownership_level>
				    <managed>false</managed>
				    <supervised>true</supervised>
				    <tethered/>
				    <battery_level/>
						<airplay_password>$AIRPLAY_PASSWORD</airplay_password>
				    <device_id>$EN0_MAC_ADDRESS</device_id>
				    <locales/>
				    <do_not_disturb_enabled>false</do_not_disturb_enabled>
				    <cloud_backup_enabled>false</cloud_backup_enabled>
				    <last_cloud_backup_date_epoch/>
				    <last_cloud_backup_date_utc/>
				    <itunes_store_account_is_active>false</itunes_store_account_is_active>
				    <computer>
				      <id>-1</id>
				    </computer>
				    <last_backup_time_epoch/>
				    <last_backup_time_utc/>
				    <site>
				      <id>-1</id>
				      <name>None</name>
				    </site>
				  </general>
				  <location>
				    <username>$3</username>
				  </location>
				  <purchasing>
				    <is_purchased>true</is_purchased>
				    <is_leased>false</is_leased>
				    <po_number/>
				    <vendor>Air Squirrels</vendor>
				    <applecare_id></applecare_id>
				    <purchase_price/>
				    <purchasing_account/>
				    <po_date/>
				    <po_date_epoch/>
				    <po_date_utc/>
				    <warranty_expires/>
				    <warranty_expires_epoch/>
				    <warranty_expires_utc/>
				    <lease_expires/>
				    <lease_expires_epoch/>
				    <lease_expires_utc/>
				    <life_expectancy>0</life_expectancy>
				    <purchasing_contact/>
				    <attachments/>
				  </purchasing>
				</mobile_device>" $JSS_URL/JSSResource/mobiledevices/$CURL_OBJECT
