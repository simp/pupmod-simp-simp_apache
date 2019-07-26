# @summary Valid log serveries for Apache
type Simp_apache::LogSeverity = Enum[
  'emerg',
  'alert',
  'crit',
  'err',
  'warn',
  'notice',
  'info',
  'debug'
]
