$baseline="mbn1"

# Cleanup
az group delete -g "rg-$baseline" -y
az deployment sub delete -n "Dep-$baseline"