-- Let the user override the Prelude via an environment variable if they want
  env:Prelude

-- -- Temporarily use master branch Prelude
-- ? https://raw.githubusercontent.com/dhall-lang/dhall-lang/master/Prelude/package.dhall

-- Fall back to the GitHub hosted version
? https://raw.githubusercontent.com/dhall-lang/dhall-lang/v10.0.0/Prelude/package.dhall
