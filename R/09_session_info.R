source(file.path("R", "00_common.R"), encoding = "UTF-8")
write_lines(capture.output(sessionInfo()), "09_session_info.txt")
