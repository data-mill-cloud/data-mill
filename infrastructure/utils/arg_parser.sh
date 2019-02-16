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

# used for testing
#echo $(cleanup_path "$1")

# variables to mandatorily return in output
VARS=(LOCATION ACTION)

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
      TARGET_FILE=$(cleanup_path "$OPTARG")
      echo "-t: overwriting target cluster configuration filename with $TARGET_FILE" >&2
      ;;
    f)
      CONFIG_FILE=$(cleanup_path "$OPTARG")
      echo "-f: overwriting default component configuration filename with $CONFIG_FILE" >&2
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
      echo "  options:"
      echo "    CONFIG_FILE: -f filename.yaml"
      echo "      -> overwrites the default component configuration filename"
      echo "    TARGET_FILE: -t filename.yaml"
      echo "      -> overwrites the default k8s configuration filename"
      echo "    COMPONENT: -c component_name"
      exit 1
    fi
  done

  [ -z "$CONFIG_FILE" ] && [ "$ACTION" != "start" ] && [ -z "$COMPONENT" ] && {
    echo "Running the default flavour configuration with an action of type install/uninstall is deprecated!" >&2
    echo "Please specificy a component with -c <component> or a different flavour with -f <file>" >&2
    exit 1
  }

  [ ! -z $COMPONENT ] && [ ! -z $CONFIG_FILE ] && {
    echo "You selected both a flavour and a component." >&2
    echo "Flavours are meant to group multiple components. Selecting a component other than those in the flavour will have no effect." >&2
    echo "Please use the default flavour (since it contains all components) or remove the component selector and update your flavour accordingly." >&2
    # this is a design choice and could be made configurable
    exit 1
  }
fi
