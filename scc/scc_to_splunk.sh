#!/bin/bash

# THIS SCRIPT IS NOT THOROUGHLY TESTED, IT'S SHARED AS AN EXAMPLE

#bash -v scc_to_splunk.sh  ORG_NAME="cloudemoz.com" PROJECT_ID="ml-sme-223918" SA_NAME="sa-scc-to-splunk001" KEY_FILENAME="mykey001.json" PUBSUB_TOPIC_NAME="scc-notifications-topic001" PUBSUB_SUB_NAME="scc-notifications-sub001" SCC_NOTIF_NAME="scc-all-findings001"
for ARGUMENT in "$@"
do

    KEY=$(echo $ARGUMENT | cut -f1 -d=)
    VALUE=$(echo $ARGUMENT | cut -f2 -d=)   

    case "$KEY" in
            ORG_NAME)           ORG_NAME=${VALUE} ;;
            PROJECT_ID)         PROJECT_ID=${VALUE} ;;  
            SA_NAME)            SA_NAME=${VALUE} ;;  
            KEY_FILENAME)       KEY_FILENAME=${VALUE} ;;  
            PUBSUB_TOPIC_NAME)  PUBSUB_TOPIC_NAME=${VALUE} ;;  
            PUBSUB_SUB_NAME)    PUBSUB_SUB_NAME=${VALUE} ;;  
            SCC_NOTIF_NAME)     SCC_NOTIF_NAME=${VALUE} ;;     
            *)   
    esac    

done

echo "ORG_NAME = $ORG_NAME"
echo "PROJECT_ID = $PROJECT_ID"
echo "SA_NAME = $SA_NAME"
echo "KEY_FILENAME = $KEY_FILENAME"
echo "PUBSUB_TOPIC_NAME = $PUBSUB_TOPIC_NAME"
echo "PUBSUB_SUB_NAME = $PUBSUB_SUB_NAME"
echo "SCC_NOTIF_NAME = $SCC_NOTIF_NAME"

gcloud config set project $PROJECT_ID

#creating a service account that will be used by Splunk to Pull data from GCP
gcloud iam service-accounts create $SA_NAME
SA_EMAIL=`gcloud iam service-accounts list --filter=name:$SA_NAME --format='value(EMAIL)'`
echo "SA_EMAIL=$SA_EMAIL"
gcloud iam service-accounts keys create $KEY_FILENAME --iam-account=$SA_EMAIL

gcloud pubsub topics create $PUBSUB_TOPIC_NAME
gcloud pubsub subscriptions create $PUBSUB_SUB_NAME --topic $PUBSUB_TOPIC_NAME

gcloud projects add-iam-policy-binding $PROJECT_ID --member=serviceAccount:$SA_EMAIL --role=roles/pubsub.viewer
gcloud pubsub subscriptions add-iam-policy-binding $PUBSUB_SUB_NAME --member=serviceAccount:$SA_EMAIL --role roles/pubsub.subscriber

ORG_ID=`gcloud organizations list --filter=DISPLAY_NAME:$ORG_NAME --format='value(ID)'`
TOPIC_FULL_NAME=`gcloud pubsub topics list --format='value(name)' --filter=name:$PUBSUB_TOPIC_NAME`
echo "ORG_ID=$ORG_ID"
echo "TOPIC_FULL_NAME=$TOPIC_FULL_NAME"

gcloud alpha scc notifications create $SCC_NOTIF_NAME --organization "$ORG_ID"  --pubsub-topic $TOPIC_FULL_NAME

# The SCC notifications will be pushed to Pub/Sub by a different service account - not the one we created above. That one is for use from Splunk (via the service account key that we created)
gcloud alpha scc notifications describe $SCC_NOTIF_NAME --organization="$ORG_ID"