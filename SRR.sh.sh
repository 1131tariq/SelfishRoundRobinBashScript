#!/bin/bash

#W19443854 - Tareq Al-Batayneh

errorMessageParameters="Positional Arguments don’t match script requirements"
errorMessageDigits="Please input valid numbers"

if test $# -ge 3 -a $# -le 4
then
    echo -e "Right number of parameters entered."

    if [[ "$2" =~ ^[0-9]+$ ]] && [[ "$3" =~ ^[0-9]+$ ]];
    then

        if [[ "$#" -gt 3 ]] && [[ ! "$4" =~ ^[0-9]+$ ]];
        then
            echo "$errorMessageDigits"
            exit 1
        fi

        if [[ $# -eq 4 ]];
        then
            let quanta=$4
        else
            let quanta=1
        fi

        echo "Digit Match"

        if test -f $1
        then
            echo "$1 data file entered:"

            index=0
            while read -r p service arrival;
            do
                Processes["$index"]="$p"
                NUTs["$index"]="$service"
                Arrivals["$index"]="$arrival"
                Statuses["$index"]="-"
                index=`expr $index + 1`
            done < $1
            let index=0
        else
            echo "Please enter a valid file."
            exit 1
        fi

        sorted=1
        while [[ sorted -gt 0 ]];
        do
            sorted=0
            i=0
            while [[ $i -le $((${#Arrivals[@]}-2)) ]];
            do
                if [[ ${Arrivals[i]} -gt ${Arrivals[$i + 1]} ]]
                then
                    tempProcess=${Processes[$i]}
                    tempNUT=${NUTs[$i]}
                    tempArrival=${Arrivals[$i]}

                    Processes[$i]=${Processes[$(($i + 1))]}
                    NUTs[$i]=${NUTs[$(($i + 1))]}
                    Arrivals[$i]=${Arrivals[$(($i + 1))]}

                    Processes[$(( $i + 1 ))]=$tempProcess
                    NUTs[$(( $i + 1 ))]=$tempNUT
                    Arrivals[$(( $i + 1 ))]=$tempArrival

                    sorted=`expr $sorted + 1`
                fi
                i=$(( $i+1 ))
            done
        done

        j=0
        while [[ $j -le $((${#Arrivals[@]}-1)) ]];
        do
            echo "${Processes[$j]} ${NUTs[$j]} ${Arrivals[$j]}"
            j=$(( $j+1 ))
        done

        echo -e "Priority increment in New Queue = $2 and in Accepted Queue = $3 and Quanta is $quanta\n"

        validoutputtype=1
        until test $validoutputtype -eq 0
        do
            read -p "Please choose desired output method: 'stdoutput' or 'file' or 'both': " output
            if test $output = "both" -o $output = "stdoutput" -o $output = "file"
            then
                let validoutputtype=0
            else
                echo -e "Please enter a valid output type"
            fi
        done

        if [[ $output == "both" || $output == "file" ]];
        then
            read -p "Please specify file path and name to output to: " filename
            touch $filename.txt
        fi

        if [[ $output == "both" || $output == "stdoutput" ]];
        then
            echo -e "T  \c"
            echo -e "T  \c" > $filename.txt
        else
            echo -e "T  \c" > $filename.txt
        fi

        for process in ${Processes[@]}
        do
            if [[ $output == "both" || $output == "stdoutput" ]];
            then
                echo -e "$process  \c"
                echo -e "$process  \c" >> $filename.txt
            else
                echo -e "$process  \c" >> $filename.txt
            fi
        done

        if [[ $output == "both" || $output == "stdoutput" ]];
        then
            echo
            echo >> $filename.txt
        else
            echo >> $filename.txt
        fi

        time=0 
        new=() 
        accepted=() 
        pointer=0 
        counter=1 
        finished=0 

        while [[ $finished < ${#Statuses[@]} ]];
        do
            finished=0 

            if [[ $output == "both" || $output == "stdoutput" ]];
            then
                if test $time -lt 10
                then
                    echo -e "$time  \c"
                    echo -e "$time  \c" >> $filename.txt
                else
                    echo -e "$time \c"
                    echo -e "$time \c" >> $filename.txt
                fi
            else
                if test $time -lt 10
                then
                    echo -e "$time  \c" >> $filename.txt
                else
                    echo -e "$time \c" >> $filename.txt
                fi
            fi

            if [[ ${#new[@]} != 0 && ${#accepted[@]} != 0 ]];
            then
                tempnew=()
                for process in ${new[@]}
                do
                    IFS=$" "
                    read -r processName nutValue priority <<< $process
                    for accProcess in "${accepted[@]}"
                    do
                        IFS=$" "
                        read -r accProcessName accNUT accPriority <<< $accProcess
                        IFS=$original_ifs
                        if [[ $accProcess == ${accepted[0]} ]]
                        then
                            minimum=$accPriority
                        fi
                        if [[ $accPriority < $minimum ]]
                        then
                            let minimum=$accPriority
                        fi
                    done
                    IFS=$original_ifs

                    if [[ $priority == $minimum || $priority -gt $minimum ]];
                    then
                        accepted+=("$processName $nutValue $priority")
                    else
                        tempnew+=("$process")
                    fi
                done
                IFS=$original_ifs
                new=("${tempnew[@]}")
            fi

            if [[ $counter -eq $quanta ]];
            then
                if [[ ${#accepted[@]} > 1 ]];
                then
                    runningProcess="${accepted[0]}"
                    for ((i = 0; i < ${#accepted[@]} - 1; i++));
                    do
                        accepted[$i]="${accepted[$((i + 1))]}"
                    done
                    accepted[${#accepted[@]} - 1]="$runningProcess"
                fi
                counter=1
            else
                if [[ ${#accepted[@]} != 0 ]];
                then
                    counter=$(( counter + 1 ))
                fi
            fi

            while [[ ${Arrivals[index]} == $time ]];
            do
                if [[ ${#accepted[@]} == 0 ]];
                then
                    accepted+=("${Processes[index]} ${NUTs[index]} 0")
                    Statuses[$index]="R"
                else
                    new+=("${Processes[index]} ${NUTs[index]} 0")
                    Statuses[$index]="W"
                fi
                index=`expr $index + 1`
            done

            wait=1
            indexs=-1
            cycle=$pointer
            processfinished=1
            while [[ $processfinished == 1 && ${#accepted[@]} != 0 ]];
            do
                IFS=$" "
                read -r pName pNUT pPriority <<< "${accepted[pointer]}"
                if [[ $pNUT > 0 ]];
                then
                    updatedpNUT=$((pNUT - 1))

                    for i in "${!Processes[@]}";
                    do
                            if [ "${Processes[i]}" == "$pName" ];
                        then
                                indexs=$i
                                break
                            fi
                    done
                    let processfinished=0
                else
                    let pointer=pointer+1
                    counter=1

                    if [ "$pointer" -gt $((${#accepted[@]} - 1)) ];
                    then
                        let pointer=0
                    fi
                    if [[ $cycle == $pointer && ${#accepted[@]} == ${#Statuses[@]} ]];
                    then
                        for i in ${!Statuses[@]}
                        do
                            Statuses[$i]="F"
                        done
                        break
                    elif [[ $cycle == $pointer ]];
                    then
                        if [[ ${#new[@]} == 0 ]];
                        then
                            let wait=0
                            break
                        else
                            accepted+=("${new[0]}")
                            new=("${new[@]:1}")
                        fi
                    fi
                fi
            done
            IFS=$original_ifs

            if [[ ${#accepted[@]} != 0 && $wait != 0 ]];
            then
                if [[ $pNUT != 0 ]];
                then
                    Statuses[$indexs]="R"
                elif [[ $pNUT == 0 ]];
                then
                    Statuses[$indexs]="F"
                fi

                update="$pName $updatedpNUT $pPriority"
                accepted[pointer]="$update"
            fi

            if [[ ${#new[@]} != 0 ]]
            then
                idx=0
                for prcss in ${new[@]}
                do
                    IFS=$" "
                    read -r npName npNut npPriority <<< $prcss
                    updatedpPriority=$((npPriority + $2))
                    update="$npName $npNut $updatedpPriority"
                    new[$idx]="$update"
                    idx=`expr $idx + 1`
                done
                IFS=$original_ifs
            fi

            if [[ ${#accepted[@]} != 0 ]];
            then
                idxz=0
                for process in ${accepted[@]}
                do
                    IFS=$" "
                    read -r apName apNut apPriority <<< $process
                    updatedaPriority=$((apPriority + $3))
                    updatea="$apName $apNut $updatedaPriority"
                    accepted[$idxz]="$updatea"
                    idxz=`expr $idxz + 1`
                done
                IFS=$original_ifs
            fi

            for status in ${Statuses[@]}
            do
                if [[ $output == "both" || $output == "stdoutput" ]];
                then
                    echo -e "$status  \c"
                    echo -e "$status  \c" >> $filename.txt
                else
                    echo -e "$status  \c" >> $filename.txt
                fi
            done

            if [[ $output == "both" || $output == "stdoutput" ]];
            then
                echo
                echo >> $filename.txt
            else
                echo >> $filename.txt
            fi

            let time=time+1

            for i in ${Statuses[@]}
            do
                if [[ $i == "F" ]];
                then
                    finished=$((finished + 1))
                else
                    finished=0
                fi
            done

            if [[ ${#accepted[@]} != 0 ]];
            then
                if [[ $updatedpNUT == 0 ]];
                then
                    if [[ $wait != 0 ]];
                    then
                        Statuses[$indexs]="F"
                    fi
                else
                    Statuses[$indexs]="W"
                fi
            fi
        done

        if [[ $output == "both" || $output == "file" ]];
        then
            echo "$filename.txt has been created with scheduling statuses calculated for provided processes."
        fi

        exit 0

    else
        echo "$errorMessageDigits"
        exit 1
    fi
else
    echo -e "$errorMessageParameters"
    exit 1
fi
