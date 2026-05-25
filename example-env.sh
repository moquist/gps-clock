export GOOGLE_API_KEY="AI...ck"
export S3BUCKET=owntracks-deploymentbucket-12341234 # just the bucket name, not the URL
export DOMAIN_WILDCARD="*.mysite.com"
export DOMAIN_NAME="locograph.mysite.com"

# curl -s -u $creds https://www.locograph.majen.net/hand-angles | jq
# returns a JSON list of angles in degrees, ordered by the handFriend list below
export CLOCK_CONFIG=$(jq -cn '
  {handFriend:["aa","bb","cc","dd","ee"],
   labelAngle:{home:0, church:45, work:90, school:130, room:180,
               unknown: 225, error:270, moving:325}}
')
