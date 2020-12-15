function [tt, y_val_nn_predict, y_real] = func_predict(data_original_filename,line_number)

load('save_nn.mat')

%% organize to data_x, data_y
% no embedding yet
TL_filename_name = 'data_TL.h5';
tt = h5read(TL_filename_name,'/tt');
slg = h5read(TL_filename_name,'/slg');
mag_3_c = h5read(TL_filename_name,'/mag_3_c');
mag_4_c = h5read(TL_filename_name,'/mag_4_c');
mag_5_c = h5read(TL_filename_name,'/mag_5_c');

data_info = h5info(data_original_filename);
data_line = h5read(data_original_filename,'/tie_line');
i1 = find(data_line==line_number, 1 );
i2 = find(data_line==line_number, 1, 'last' );

tt = tt(i1:i2);
slg = slg(i1:i2,:);
mag_3_c = mag_3_c(i1:i2,:);
mag_4_c = mag_4_c(i1:i2,:);
mag_5_c = mag_5_c(i1:i2,:);
data_x = [mag_3_c,mag_4_c,mag_5_c];


for ch_i = 1:length(add_channel_num)    
    channel_1_name = data_info.Datasets( add_channel_num(ch_i) ).Name;
    channel_1 = h5read(data_original_filename,['/' channel_1_name]);
    channel_1 = channel_1(i1:i2);
    % filter
    channel_1_f = channel_1;
    for lowpass_i = 1:10
        channel_1_f = lowpass(channel_1_f,1e-10);
    end 
       
    channel_1_f_cut = 55;
    channel_1 = movmean(channel_1,10);
    channel_1_f(1:channel_1_f_cut) = channel_1(1:channel_1_f_cut);
    channel_1_f(end-channel_1_f_cut+1:end) = channel_1(end-channel_1_f_cut+1:end);
    
    data_x = [data_x, channel_1_f];    
end

dim_x = size(data_x,2);

for d_i = 1:dim_x
    data_x(:,d_i) = data_x(:,d_i) - renorm_set(d_i,1);
    data_x(:,d_i) = data_x(:,d_i) / renorm_set(d_i,2);
end

val_r_step_length = length(slg) - 2 * half_input_wid;
y_real = slg';
y_real = y_real(half_input_wid+1:end-half_input_wid);
tt = tt(half_input_wid+1:end-half_input_wid);

dim_in = dim_x * ( 2*half_input_wid + 1);
%% organize to x_train, y_train, x_val, y_val
% with embedding

val_start_point = half_input_wid;

x_val = zeros(dim_in,val_r_step_length);
for d_i = -half_input_wid:half_input_wid
    x_val( (half_input_wid-d_i)*dim_x+1 : (half_input_wid-d_i)*dim_x+dim_x,:) = ...
        data_x(val_start_point-d_i+1 : val_start_point-d_i+val_r_step_length,:)';
    x_val( (half_input_wid+d_i)*dim_x+1 : (half_input_wid+d_i)*dim_x+dim_x,:) = ...
        data_x(val_start_point+d_i+1 : val_start_point+d_i+val_r_step_length,:)';
end


%% main NN

y_val_nn_predict_set = [];
for hyper_repeat_i = 1:hyper_repeat_num
    net = net_set{hyper_repeat_i};
    y_val_nn_predict_set = [y_val_nn_predict_set; net(x_val)];
end
y_val_nn_predict = mean(y_val_nn_predict_set,1);

end

