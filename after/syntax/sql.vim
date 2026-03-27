if exists('b:current_syntax')
  syn case ignore

  " Supplement the generic SQL syntax with common Snowflake-specific tokens.
  syn keyword sqlSnowflakeKeyword qualify ilike rlike lateral sample pivot unpivot flatten
  syn keyword sqlSnowflakeKeyword masking secure transient warehouse recursive
  syn keyword sqlSnowflakeFunction iff nvl2 zeroifnull nullifzero try_cast try_to_date
  syn keyword sqlSnowflakeFunction try_to_time try_to_timestamp try_to_number
  syn match sqlSnowflakeStage /@\%(\k\|[.$\/~-]\)\+/

  hi def link sqlSnowflakeKeyword sqlKeyword
  hi def link sqlSnowflakeFunction Function
  hi def link sqlSnowflakeStage Identifier

  syn case match
endif
