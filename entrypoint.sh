#!/bin/sh -l

uuid="a$(cat /proc/sys/kernel/random/uuid)"

aws cloudformation create-change-set --stack-name $INPUT_STACK_NAME --template-body file://$INPUT_TEMPLATE_BODY --change-set-name=$uuid
if [ $? -ne 0 ]; then
  echo "[ERROR] failed to create change set."
  exit 1
fi

for i in `seq 1 5`; do
  aws cloudformation describe-change-set --change-set-name=$uuid --stack-name=$INPUT_STACK_NAME --output=json > $uuid.json 
  status=$(cat $uuid.json | jq -r '.Status')
  if [ ${status} = "CREATE_COMPLETE" ]; then    
    break
  else
    echo "change set is now creating..."
    sleep 3
  fi
done

aws cloudformation delete-change-set --change-set-name=$uuid --stack-name=$INPUT_STACK_NAME
if [ $? -ne 0 ]; then
  echo "[ERROR] failed to delete change set."
fi

if [ ${status} != "CREATE_COMPLETE" ]; then
  echo "[ERROR] failed to create change set."
  exit 1
fi

result=$(cat $uuid.json | jq -c)
echo "::set-output name=result::$result"
echo "::set-output name=result_file_path::$uuid.json"
