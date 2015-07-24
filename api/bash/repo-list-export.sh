#!/usr/bin/env bash
#
# set GITHUB_TOKEN to your GitHub or GHE access token
# set GITHUB_API_ENDPOINT to your GHE API endpoint (defaults to https://api.github.com)

if [ -n "$GITHUB_API_ENDPOINT" ]
  then
    url=$GITHUB_API_ENDPOINT
  else
    url="https://api.github.com"
fi

token=$GITHUB_TOKEN

dependency_test()
{
  for dep in curl jq ; do
    command -v $dep &>/dev/null || { echo -e "\n${_error}Error:${_reset} I require the ${_command}$dep${_reset} command but it's not installed.\n"; exit 1; }
  done
}

token_test()
{
  if [ -n "$token" ]
    then
    token_cmd="Authorization: token $token"
  else
    echo "You must set a Personal Access Token to the GITHUB_TOKEN environment variable"
    exit 1
  fi
}

usage()
{
  echo -e "Usage: $0 [options] <orgname>...\n"
  echo "Options:"
  echo " -h | --help                      Help"
  echo ""
}

# Progress indicator
working() {
   echo -n "."
}

work_done() {
  echo -n "done!"
  echo -e "\n"
}

get_repos()
{
  last_repo_page=$( curl -s --head -H "$token_cmd" "$url/orgs/$org/repos?per_page=100" | sed -nE 's/^Link:.*per_page=100.page=([0-9]+)>; rel="last".*/\1/p' )

  if [ "$last_repo_page" == "" ]
  then
    echo "Fetching repository list for '$org' organization on GitHub.com"
    all_repos=($( curl -s -H "$token_cmd" "$url/orgs/$org/repos?per_page=100" | jq --raw-output '.[].name'  | tr '\n' ' ' ))
    total_repos=$( echo $all_repos | sed 's/\"//g' | wc -w | tr -d "[:space:]" )
    printf '%s\n' "${all_repos[@]}" | sort --ignore-case > $org.txt
    total_repos=$( echo "${all_repos[@]}" | wc -w | tr -d "[:space:]" )
    echo ""
    echo "Total # of repositories in "\'$org\'": $total_repos"
    echo "List saved to $org.txt"
  else
    echo "Fetching repository list for '$org' organization on GitHub.com"
    working
    all_repos=()
    for (( j=1; j<=$last_repo_page; j++ ))
    do
      paginated_repos=$( curl -s -H "$token_cmd" "$url/orgs/$org/repos?per_page=100&page=$j" | jq --raw-output '.[].name'  | tr '\n' ' ' )
      all_repos=(${all_repos[@]} $paginated_repos)
    done
    work_done
    printf '%s\n' "${all_repos[@]}" | sort --ignore-case > $org.txt
    total_repos=$( echo "${all_repos[@]}" | wc -w | tr -d "[:space:]" )
    echo "Total # of repositories in "\'$org\'": $total_repos"
    echo "List saved to $org.txt"
  fi
}

#### MAIN

dependency_test

token_test

if [ -z "$*" ] ; then
  echo "Error: no organization name entered" 1>&2
  echo
  usage
  exit 1
fi

while [ "$1" != "" ]; do
  case $1 in
    -h | --help )         usage
                          exit ;;
    -* )                  echo "Error: invalid argument: '$1'" 1>&2
                          echo
                          usage
                          exit 1;;
    * )                   org="$1"
                          get_repos
  esac
  shift
done

exit 0
