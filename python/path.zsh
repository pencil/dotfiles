# Homebrew links only versioned names (python3, pip3) into its bin; the
# unversioned python/pip live in libexec/bin of the default formula.
if type brew &> /dev/null && [ -d "$(brew --prefix)/opt/python/libexec/bin" ]
then
  export PATH="$(brew --prefix)/opt/python/libexec/bin:$PATH"
fi
