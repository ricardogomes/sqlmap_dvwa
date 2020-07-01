
# Functions to handle proper construction of strings

generate_setup_data(){
cat <<EOF
create_db=Create+%2F+Reset+Database&user_token=$USER_TOKEN
EOF
}

generate_post_data(){
cat <<EOF
username=admin&password=password&Login=Login&user_token=$USER_TOKEN
EOF
}

generate_cookie(){
cat <<EOF
PHPSESSID=$PHPSESSID; security=low
EOF
}

# Environment variables
TEMP_OUTPUT=/tmp/temp_output

echo "Testing SQLMAP against DVWA"

echo "[Docker] Setting up DVWA"
docker run --rm --name dvwa -itd -p 80:80 vulnerables/web-dvwa 1> /dev/null

echo "[Docker] Wainting for DVWA to be live on http://localhost"

until $(curl --output /dev/null --silent --head --fail http://localhost); do
    printf '.'
    sleep 1
done

echo "[Docker] DVWA Running" 

echo "[CURL] Getting user_token and PHPSESSIONID"

curl http://localhost/login.php --silent -D /tmp/dvwa_headers -o /tmp/dvwa_login --cookie-jar /tmp/dvwa_cookies

USER_TOKEN=$(cat /tmp/dvwa_login | tidy -asxml 2> /dev/null  | xmlstarlet sel -t -v '//_:input[@name="user_token"]/@value' 2> /dev/null)
PHPSESSID=$(grep PHP /tmp/dvwa_cookies | awk '{print $7}')

echo "[CURL] Setting up database"

curl -X POST 'http://localhost/setup.php' \
     -H 'Content-Type: application/x-www-form-urlencoded' \
     -H 'Referer: http://localhost/setup.php' \
     -H "Cookie: $(generate_cookie)" \
     --data-raw "$(generate_setup_data)" \
     -L --output $TEMP_OUTPUT --silent

if grep -q "Database has been created" $TEMP_OUTPUT
then
	echo "[DVWA] Database sucessfully created"
else
	echo "[DVWA] ERROR Creating Database"
	docker container stop dvwa
	exit 1
fi

echo "[CURL] Refreshing Tokens"
curl http://localhost/login.php --silent -D /tmp/dvwa_headers -o /tmp/dvwa_login --cookie-jar /tmp/dvwa_cookies

USER_TOKEN=$(cat /tmp/dvwa_login | tidy -asxml 2> /dev/null  | xmlstarlet sel -t -v '//_:input[@name="user_token"]/@value' 2> /dev/null)
PHPSESSID=$(grep PHP /tmp/dvwa_cookies | awk '{print $7}')

echo "[CURL] Loging in"
curl -L  http://localhost/login.php \
        -H "Cookie: $(generate_cookie)" \
        -H 'Cache-Control: no-cache' \
        --data-raw "$(generate_post_data)" \
	--output $TEMP_OUTPUT --silent

if grep -q "Welcome to Damn Vulnerable Web Application!" $TEMP_OUTPUT
then
        echo "[DVWA] Login Sucessful"
else
        echo "[DVWA] ERROR Login Unsucessful"
        docker container stop dvwa
        exit 1
fi

echo "[SQLMAP] Testing DVWA - SQL Injection"

docker run --rm -it --network host -v /tmp/sqlmap:/root/.sqlmap/ paoloo/sqlmap  \
	-u "http://localhost/vulnerabilities/sqli_blind/?id=1&Submit=Submit" \
	--cookie="$(generate_cookie)"  \
	--dbms=MySQL --flush-session 

echo "[Docker] Clearing docker environment"
docker container stop dvwa


