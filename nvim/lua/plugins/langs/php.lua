return {
  {
    "V13Axel/neotest-pest",
    "olimorris/neotest-phpunit",
  },

  {
    "neotest-pest",
    ["neotest-phpunit"] = {
      root_ignore_files = { "tests/Pest.php" },
    },
  },
}
