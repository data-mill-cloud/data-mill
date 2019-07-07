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

OPTIONS=":sarlhiuxpd:t:f:c:"

while getopts $OPTIONS opt; do
  case $opt in
    d)
      if [ "$OPTARG" != "net" ] && [ "$OPTARG" != "app" ]; then
        echo "-d expects an environment type in {'net', 'app'}"
        exit 1
      fi
      # spawn debug environment
      ACTION="debug"
      DPOD="$OPTARG"
      echo "-d: debug mode "${DPOD}" requested"
      ;;
    p)
      echo "-p: start kubectl reverse proxy"
      ACTION="proxy"
      ;;
    s)
      echo "-s: start existing cluster without installing further dependencies"
      ACTION="start"
      ;;
    a)
      echo "-a: alt cluster"
      ACTION="alt"
      ;;
    r)
      echo "-r: running to remote cluster"
      LOCATION="remote"
      ;;
    l)
      echo "-l: running local cluster"
      LOCATION="local"
      ;;
    h)
      echo "-h: running cluster from existing KUBECONFIG"
      LOCATION="hybrid"
      ;;
    i)
      echo "-i: installing flavour/component"
      ACTION="install"
      ;;
    u)
      echo "-u: uninstalling flavour/component"
      ACTION="delete"
      ;;
    x)
      echo "-x: uninstalling flavour and deleting cluster"
      ACTION="delete_all"
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
      echo "-f: using the configuration at $FLAVOUR_FILE"
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

# flavour (defines the config) and cluster location should always be set, as this would otherwise lead to mistakes
for var in "${VARS[@]}"
do
  if [ -z ${!var} ]; then
    echo "Usage: $0 [location] [action] [flavour] [options]"
    echo "  params:"
    echo "    LOCATION: -l (local cluster), -r (remote cluster), -h (kubeconfig cluster)"
    echo "    ACTION:"
    echo "      -p (start proxy), -d (debug mode)"
    echo "      -s (start/create cluster), -a (alt cluster)"
    echo "      -i (install flavour/component), -u (uninstall flavour/component), -x (uninstall and delete cluster)"
    echo "    FLAVOUR_FILE: -f path/filename.yaml"
    echo "      -> sets the project flavour file"
    echo "  options:"
    echo "    TARGET_FILE: -t path/filename.yaml"
    echo "      -> overwrites the default k8s configuration filename"
    echo "    COMPONENT: -c component_name"
    exit 1
  fi
done
