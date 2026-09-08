if [ -n "$(ssh -T git@github.com 2>&1 | grep authenticated))" ]; then
  export GITHUB_AUTHENTICATED=true
else
  export GITHUB_AUTHENTICATED=false
fi
