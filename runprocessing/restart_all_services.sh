sh event_service.sh start

screen -S runvalidcompletemonitor -dm bash -c "$(printf "sh runvalidcompletemonitor.sh &\n echo \$!> runvalidcompletemonitor.lock;\n exec sh;\n")" 

screen -S mini_dashboard_aggr_split -dm bash -c "$(printf ". ./mini_dashboard_aggr_split.sh; restart_all &\n echo \$!> mini_dashboard_aggr_split.lock;\n exec sh;\n")"
