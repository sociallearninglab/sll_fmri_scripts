root = '/Volumes/sll-members/fmri/'
project = 'SwiSt'

path = strcat(root,project,'/behavioral')
cd(path)

%for i = 4:4
for i = 5:23
    chunks = {}
    duration = {}
    onset = {}
    targets = {}
    
    runs_file = {}
    ips_list = {}
    
    %total number of events
    total_num = 0
    
    if i < 10
        subjects = strcat('0',num2str(i))
    else
        subjects = num2str(i)
    end
    
    %we write ips values to this file:
    ips_file = fopen(strcat('SLL_',project,'_',subjects,'.ips.txt'),'w')
    
    fileID = fopen(strcat('SLL_',project,'_',subjects,'.txt'),'w')
    behvs = dir(strcat('*',subjects,'*mvpa*.mat'))
    current_chunk = 0
    for behv = behvs'
        %next run/chunk
        current_struct = load(behv.name)
        ips_list{end+1} = current_struct.ips
        for j = 1:length(current_struct.spm_inputs)
            %next regressor
            current_cond = current_struct.spm_inputs(j).name
            for k = 1:length(current_struct.spm_inputs(j).ons)
                current_ons = current_struct.spm_inputs(j).ons(k)
                current_dur = current_struct.spm_inputs(j).dur(k)
                
                %we have an event!
                chunks{end+1} = current_chunk
                duration{end+1} = current_dur
                onset{end+1} = current_ons
                targets{end+1} = current_cond
                
                total_num = total_num + 1
            end
        end
        current_chunk = current_chunk + 1 %end of the current behavioral file (run/chunk)
        runs_file{end+1} = fopen(strcat('SLL_',project,'_',subjects,'_',num2str(current_chunk),'.txt'),'w')
    end
    
    fprintf(ips_file,strcat(num2str(current_chunk),'\n')) %at this point, current_chunk holds the count of runs
    for counter = 1:current_chunk
        if counter == current_chunk
            %end of file
            fprintf(ips_file,num2str(ips_list{counter}))
        else
            fprintf(ips_file,strcat(num2str(ips_list{counter}),'\n'))
        end
    end
    
    i=1
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    for cnt = 1:total_num
        fprintf(fileID,num2str(chunks{cnt}))
        if cnt == total_num
            fprintf(fileID,'\n')
        else
            fprintf(fileID,',')
        end
        
        
        if cnt > (total_num/current_chunk)*i %we have reached the next run
            i = i + 1
        end
        fprintf(runs_file{i},num2str(chunks{cnt}))
        if cnt == (total_num/current_chunk)*i
            fprintf(runs_file{i},'\n')
        else
            fprintf(runs_file{i},',')
        end
    end
    i=1
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    for cnt = 1:total_num
        fprintf(fileID,num2str(duration{cnt}))
        if cnt == total_num
            fprintf(fileID,'\n')
        else
            fprintf(fileID,',')
        end
        
        
        if cnt > (total_num/current_chunk)*i %we have reached the next run
            i = i + 1
        end
        fprintf(runs_file{i},num2str(duration{cnt}))
        if cnt == (total_num/current_chunk)*i
            fprintf(runs_file{i},'\n')
        else
            fprintf(runs_file{i},',')
        end
    end
    i=1
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    for cnt = 1:total_num
        fprintf(fileID,num2str(onset{cnt}))
        if cnt == total_num
            fprintf(fileID,'\n')
        else
            fprintf(fileID,',')
        end
        
        
        if cnt > (total_num/current_chunk)*i %we have reached the next run
            i = i + 1
        end
        fprintf(runs_file{i},num2str(onset{cnt}))
        if cnt == (total_num/current_chunk)*i
            fprintf(runs_file{i},'\n')
        else
            fprintf(runs_file{i},',')
        end
    end
    i=1
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    for cnt = 1:total_num
        fprintf(fileID,targets{cnt})
        if cnt == total_num
            %fprintf(fileID,'\n')
        else
            fprintf(fileID,',')
        end
        
        
        if cnt > (total_num/current_chunk)*i %we have reached the next run
            i = i + 1
        end
        fprintf(runs_file{i},targets{cnt})
        if cnt == (total_num/current_chunk)*i
            %fprintf(runs_file{i},'\n')
        else
            fprintf(runs_file{i},',')
        end
    end
end