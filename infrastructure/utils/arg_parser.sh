cleanup_path(){
        if [[ -f $1 ]]; then
                # retrieve parent directory
                path=$(dirname "$1")
                # retrieve file name
                fname=$(basename "$1")
        else
                path=$1
        fi

        # if we have a relative path then we need to retrieve the absolute path
        # follow the relative path and return the absolute one
        if [[ -d $1 ]]; then
                # return a path
                echo `cd "$path"; pwd`
        else
                # return a path to the file
                echo `cd "$path"; find "$(pwd)" -name $fname`
        fi
}

# variables to mandatorily return in output
VARS=("LOCATION" "ACTION" "FLAVOUR_FILE")

OPTIONS=":dsrliut:f:c:"

while getopts $OPTIONS opt; do
  case $opt in
    d)
      echo "-d: debug mode enabled, spawning environment"
      ACTION="debug"
      break
      ;;
    s)
      echo "-s: start existing cluster without installing further dependencies"
      ACTION="start"
      ;;
    r)
      echo "-r: running to remote cluster"
      LOCATION="remote"
      ;;
    l)
      echo "-l: running local cluster"
      LOCATION="local"
      ;;
    i)
      echo "-i: installing infrastructure"
      ACTION="install"
      ;;
    u)
      echo "-u: uninstalling infrastructure"
      ACTION="delete"
      ;;
    t)
      (ls "$OPTARG" >> /dev/null 2>&1) || {
        echo "-t expects a path to the yaml file containing cluster information, e.g. -t path/default.yaml"
        echo "$OPTARG not found!"
        exit 1
      }
      TARGET_FILE=$(cleanup_path "$OPTARG")
      echo "-t: overwriting target cluster configuration filename with $TARGET_FILE"
      ;;
    f)
      # if the passed path exists convert it to absolute, otherwise raise error
      (ls "$OPTARG" >> /dev/null 2>&1) || {
        echo "$OPTARG not found!"
        echo "-f expects a path to the flavour file, e.g. -f flavours/default.yaml"
	exit 1
      }
      FLAVOUR_FILE=$(cleanup_path "$OPTARG")
      echo "-f: overwriting default component configuration filename with $FLAVOUR_FILE"
      ;;
    c)
      COMPONENT=$(basename "$OPTARG")
      echo "-c: running for the sole component $COMPONENT" >&2
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
  esac
done

# print usage if any of the variables is not set
if [ "$ACTION" != "debug" ]; then
  for var in "${VARS[@]}"
  do
    if [ -z ${!var} ]; then
      echo "Usage: $0 [debug-mode] [params] [options]"
      echo "  debug mode:"
      echo "    DEBUG: -d"
      echo "  params:"
      echo "    LOCATION: -l (local cluster), -r (remote cluster)"
      echo "    ACTION: -s (start only), -i (install), -u (uninstall)"
      echo "    FLAVOUR_FILE: -f path/filename.yaml"
      echo "      -> sets the project flavour file"
      echo "  options:"
      echo "    TARGET_FILE: -t path/filename.yaml"
      echo "      -> overwrites the default k8s configuration filename"
      echo "    COMPONENT: -c component_name"
      exit 1
    fi
  done
fi
