#common.sh

DATE=`date +%Y%m%d`
DATEYEAR=`date +%Y`

PATH=$PATH:./:/sbin:/usr/sbin
next (){
  echo -n "Next?(enter to next, C-c to quit): "
  read
}
echo_and_exec(){
  echo $1 ; $1
}
