
if [ ! -n "$EXECUTION_URL" ]
then
  EXECUTION_URL="http://localhost:8551"
fi;

if [ ! -n "$MEVBOOST_URL" ]
then
  MEVBOOST_URL="http://localhost:18550"
fi;

# This will be available in /data/jwtsecret
if [ ! -n "$JWT_SECRET" ]
then
  JWT_SECRET="0xdc6457099f127cf0bac78de8b297df04951281909db4f58b43def7c7151e765d"
fi;

if [ ! -n "$FEE_RECIPIENT" ]
then
  FEE_RECIPIENT="0x0000000000000000000000000000000000000000"
fi;

# Specify this as "-min-bid <value>"
if [ ! -n "$MIN_BUILDERBID" ]
then
  MIN_BUILDERBID=0
fi;

