# Security Command Center findings export to Splunk
Using the SCC notifications feature. Sends a message to Pub/Sub whenever there's a new finding.

Then we can use the service account key that gets created as part of the script to pull data from Splunk - via the Splunk addon for Google Cloud (https://docs.splunk.com/Documentation/AddOns/released/GoogleCloud/About).
Alternatively, we can use the Push to Splunk Dataflow template https://cloud.google.com/dataflow/docs/guides/templates/provided-streaming#pubsub-to-splunk . 

So in GCP we just need to run this 1 script, then configure Splunk to pull.

If you want to use push, add another gcloud command to the script and configure a HEC token from Splunk.
Here's the command in my case - notice it's super basic, 1 worker, no processing function etc.
```
gcloud dataflow jobs run splk --gcs-location=gs://dataflow-templates/latest/Cloud_PubSub_to_Splunk --network=splunk-network --region=us-east1 --subnetwork=regions/us-east1/subnetworks/splunk-network --worker-zone=us-east1-b --max-workers 1 --worker-machine-type n1-standard-1 --parameters inputSubscription=projects/MYPRODID/subscriptions/scc-notifications-sub001,token=MYHECTOKEN,url=http://10.142.0.4:8088,outputDeadletterTopic=projects/MYPROJID/topics/splunk_deadletter_topic
```