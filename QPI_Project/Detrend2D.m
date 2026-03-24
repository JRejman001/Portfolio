function OutFunc = Detrend2D(InFunc)
[rows cols] = size(InFunc);
OutFunc = zeros([rows cols]);
ny = rows;
nx = cols;
an1=nx;
an2=ny;
a11=an2*an1*(an1+1)*(2*an1+1)/6;
a12=an1*(an1+1)*an2*(an2+1)/4;
a13=an2*an1*(an1+1)/2;
a22=an1*an2*(an2+1)*(2*an2+1)/6;
a23=an1*an2*(an2+1)/2;
a33=an1*an2;

b1=0;b2=0;b3=0;

b3 = sum(sum(InFunc));
[b1_temp b2_temp] = meshgrid(1:1:nx,1:1:ny);
b1 = sum(sum(InFunc.*b1_temp));
b2 = sum(sum(InFunc.*b2_temp));
% for i=1:ny
%     for j=1:nx
%         b1=b1+InFunc(i,j)*j;
%         b2=b2+InFunc(i,j)*i;
% %         b3=b3+InFunc(i,j);
%     end;
% end;

deta=a11*(a22*a33-a23*a23)+a12*(a23*a13-a12*a33)+a13*(a12*a23-a22*a13);
fj=(b1*(a22*a33-a23*a23)+a12*(a23*b3-b2*a33)+a13*(b2*a23-a22*b3))/deta;
fi=(a11*(b2*a33-a23*b3)+b1*(a23*a13-a12*a33)+a13*(a12*b3-b2*a13))/deta;
f0=(a11*(a22*b3-b2*a23)+a12*(b2*a13-a12*b3)+b1*(a12*a23-a22*a13))/deta;

ftemp = fj.*b1_temp+fi.*b2_temp+f0;
OutFunc = InFunc - ftemp;
% for i=1:ny
%     for j=1:nx
%         ftemp=fj*j+fi*i+f0;
% 	    OutFunc(i,j)=InFunc(i,j)-ftemp;
%     end;
% end;       b3=b3+InFunc(i,j);
%     end;
% end;

deta=a11*(a22*a33-a23*a23)+a12*(a23*a13-a12*a33)+a13*(a12*a23-a22*a13);
fj=(b1*(a22*a33-a23*a23)+a12*(a23*b3-b2*a33)+a13*(b2*a23-a22*b3))/deta;
fi=(a11*(b2*a33-a23*b3)+b1*(a23*a13-a12*a33)+a13*(a12*b3-b2*a13))/deta;
f0=(a11*(a22*b3-b2*a23)+a12*(b2*a13-a12*b3)+b1*(a12*a23-a22*a13))/deta;

ftemp = fj.*b1_temp+fi.*b2_temp+f0;
OutFunc = InFunc - ftemp;
% for i=1:ny
%     for j=1:nx
%         ftemp=fj*j+fi*i+f0;
% 	    OutFunc(i,j)=InFunc(i,j)-