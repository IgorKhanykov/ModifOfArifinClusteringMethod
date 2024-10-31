%��������� (������� ������������ ����) ���������� ��������������� 
%������������� �������� ����������� �� �������� ������ �� ������ ������ 
%������� � ������������ ������� ���������� ����� ������ ������� ��������� � 
%������������ ������� �������� ��������� �� ��������. ���������� ����� 
%���������� ������������� ����� ������� �������� ���������� ��������� 
%������������ ������. �������� �������� ��������� �� �������� ����������� 
%����� ���������� �������.

% �����: �.�.�. ������� 23 ���� ������� �.�.  
% ���� ������ ����������������:     22-07-2024
% ���� ��������� ����������������:  02-08-2024
% ����(-�) �������� ������:         



%%�������� ����������� � ���� ����������:  
%% �������������� ����������: iIntensitiesLength --> ikIntensitiesLength
%%

% %�������� ����������� (������ ��������� 0]) ��������������� �� ������� (������ 1]) �� ����� ���������� � ������� ���������
% % 0] ��������� � ����������� �����������
% % -- 0.1) ������� ��������� ����������� 
[fileName, pathToFolder]=uigetfile({'*.png'},'Select png-image...');
pathToFile=fullfile(pathToFolder, fileName);
if( size(pathToFile,2)==3)
    msgbox('Empty file path! Select image. EXITING program!');
    return;
end;
img=imread(pathToFile);
figure('Name', 'Input Image','NumberTitle','off'), imshow(img);

% -- 0.2) ������� ������ ����� �� ������ ���������� �����������
splitedString = strsplit(fileName,'.');
fileTitle=char(splitedString(1));
pathToFolderNew=fullfile(pathToFolder,fileTitle);
if ~exist(pathToFolderNew, 'dir')
    mkdir(pathToFolderNew);
else
    msgbox('Destination folder already exists! Rename folder or image file and try again. EXITING parogram!');
    return;
end;

% -- 0.3) ��������� ���������� �������� ������� � � ������ �������� 
% �������� ����������� ��������� ��� � ������� ������
[numOfRows, numOfCols, iNumOfChannels]=size(img);
iNumberOfPixelsTotal=numOfRows*numOfCols;
if (iNumOfChannels<1 || (iNumOfChannels>3))
    sMessage='Error input image file! Number of color channels is less than 1 or greater than 3. EXITING program.';
    msgbox(sMessage);
    return;
end;
if (iNumOfChannels>=1 && iNumOfChannels<=3)
    if (iNumOfChannels==1)
        sMessage='Input image is grayscale.';
        msgbox(sMessage);
        imgGS=img;
    end;
    if (iNumOfChannels==3)
        sMessage='Input image has 3 color channels. No time for color check! Converting to grayscale format anyway.';
        %����� ������ ���� �������� ����� � �����������, �� ����� ��� ���.
        %� ����� ������ ������������� � ������� ������. � ����� ���������
        %���������� iNumOfChannels ����� ��� ������ ���� ����������� ���
        %����������: 8-������ (1 �����) ��� 24-������ (3 ������).
        msgbox(sMessage);
        imgGS=rgb2gray(img);
    end; 
    if(iNumOfChannels~=1 && iNumOfChannels~=3) 
        sMessage='Unusual number of color channels in selected image. EXITING program!'; 
        msgbox(sMessage);
        return;
    end;
else
    sMessage='Unusual number of color channels in selected image. EXITING program!'; 
    msgbox(sMessage);
    return;
end;
figure('Name', 'Grayscale Image','NumberTitle','off'), imshow(imgGS);

% 1] ������� ������� �������.
%1.1 ������� ������ ��������, 
% % aIntensities=   [100,101,102,103,104,105,106,107,108,109,110]; % ����� ��������
% % ikIntensitiesLength=size(aIntensities,2);          % ����� ��������
% !!���������������� ������� ������ � ��C�������������� ������ ��� ������ �
% �������� ������������
ikIntensitiesLength=256;
aIntensities=zeros(1,ikIntensitiesLength);
for i=1:1:256
    aIntensities(i)=i-1;
end;

%1.2 ������� � ��������� ������ ������
% ����������� ����������� �� �������� ������
% % aFrequences=[0,1,4,8,10,5,0,0,15,3,0];          % ����������� ������ ��������
% % iNumberOfPixelsTotal=0;     % ����� ��������
% % for i=1:1:ikIntensitiesLength
% %     iNumberOfPixelsTotal=iNumberOfPixelsTotal+aFrequences(i);
% % end;
% !!���������������� ������� ������ � ��C�������������� ������ ��� ������ �
% �������� ������������
figHistBars=figure('Name', 'Histogram of the Grayscale Image','NumberTitle','off'), ImageHistogram=histogram(imgGS(:,:,1),256), grid;
xlabel('Order Number of Gray Intensity');
ylabel('Quantity of Each Intensity');
% -- ��������� �����������
fileNameNew='ImageHistogram.png';
pathToFileNew=fullfile(pathToFolderNew, fileNameNew);
if isempty(pathToFileNew)
    msgbox('1.2) Error! String variable "pathToFileNew" is empty. No path to file is specified to save histogram. EXITING program.');
    return;
else
    saveas(figHistBars, pathToFileNew);%gcf
end;
aFrequences=ImageHistogram.Values;

% -- ����������� ���������� �� "������� ��������" (������� � �������� ������ 0)
iIntensitiesNumOfNonEmpty=0;
for i=1:1:ikIntensitiesLength
    if(aFrequences(i)~=0)
        iIntensitiesNumOfNonEmpty=iIntensitiesNumOfNonEmpty+1;
    end;
end;
% ��������
% -- ���� ������ "������� �������" � ����������� (�����������, ����������� �������� ������)
if(iIntensitiesNumOfNonEmpty==0)
    msgbox('1.2.Image is blank! Variable iIntensitiesNumOfNonEmpty must be grater than 0 for the image. EXITING program!');
    return;
end;


%1.3 �������������� ��������. 
% -- ������� ������ ������ ���������
aClusters=zeros(1,ikIntensitiesLength);
% -- �������������� �������� (���� ������� - ���� �������, �� 
%"������� �������" �� �������� �������)
% ���� ������ ������� "�������", �� ������� � ��������� �� "�������"
% ���� ��������� ������� "�������", �� ������� � ���������� �� "�������"
if(aFrequences(1)==0)
    aClusters(1)=1;
    k=1;
    for i=2:1:ikIntensitiesLength
        if(aFrequences(i)==0)
            aClusters(i)=aClusters(i-1);
        else
            aClusters(i)=k;
            k=k+1;
        end;
    end;
else
    k=1;
    for i=1:1:ikIntensitiesLength
        if(aFrequences(i)==0)
            aClusters(i)=aClusters(i-1);
        else
            aClusters(i)=k;
            k=k+1;
        end;
    end;
end;
iNumberOfClustersTotal=k-1;   % ����� ��������� � ����������� �����
iNumberOfClustersLeft=iNumberOfClustersTotal; % ������� ��������� �������� �� ����������� � ���� �����
%��������:
if(iNumberOfClustersTotal==1)
    msgbox('1.3. Number of clustes is equal 1! Image is plain. EXITING program.');
    return;
end;

% 1.4. ��������� ����� �������� � ������ ��������
% -- ������� ������ ������, �������� ����� �������� � ������ ��������
aNumberOfPixelsInClusters=zeros(1,ikIntensitiesLength);
% -- ��������� � ���������� ����� �������� � ������ ��������.
iClusterToConsider=1;
iSumOfPixelsInCluster=0;
for i=1:1:ikIntensitiesLength
    % ��� ������ ������� � "��������������" �������� ���������� ����� �������� �� ������ ������� � ��������
    if(i<ikIntensitiesLength &&  aClusters(i)==iClusterToConsider && aClusters(i+1)==iClusterToConsider)
        bFlag=true;
        j=i;
        while(bFlag==true && j<=ikIntensitiesLength) % �������������� ������� �� ��������
            iSumOfPixelsInCluster=iSumOfPixelsInCluster+aFrequences(j);
            if(j==ikIntensitiesLength)
                bFlag=false;
                continue;
            end;
            if(aClusters(j)~=aClusters(j+1))
                bFlag=false;
            end;
            j=j+1;
        end;
        bFlag=true;
        j=i;
        while(bFlag==true && j<=ikIntensitiesLength) % ��������� ����� �������� � �������� � ������� ������ �������
            aNumberOfPixelsInClusters(j)=iSumOfPixelsInCluster;
            if(j==ikIntensitiesLength)
                bFlag=false;
                continue;
            end;
            if(aClusters(j)~=aClusters(j+1))
                bFlag=false;
            end;
            j=j+1;
        end;
        iSumOfPixelsInCluster=0;
        iClusterToConsider=iClusterToConsider+1;
    end;
    %��� "��������������" �������� � �������� ������� ���������
    if(i<ikIntensitiesLength && aClusters(i)==iClusterToConsider && aClusters(i+1)==iClusterToConsider+1)
        aNumberOfPixelsInClusters(i)=aFrequences(i);
        iClusterToConsider=iClusterToConsider+1;
    end;
    %��� "��������������" �������� � ����� ������� ���������  
    if(i==ikIntensitiesLength && aClusters(i)==iClusterToConsider && aClusters(i-1)==iClusterToConsider-1)
        aNumberOfPixelsInClusters(i)=aFrequences(i);
    end;
end;
% ��������.  �������� "����" ������ ������������ � �������
% aNumberOfPixelsInClusters. ����������� ����� �������� � �������� ����� 1.
for i=1:1:ikIntensitiesLength
    if (aNumberOfPixelsInClusters(i)==0)
        sMessage=strcat('1.4. Error! Cluster '+num2str(aClusters(i))+' contain 0 pixels! EXITING program.');
        msgbox(sMessage);
        return;
    end;
end;

% 1.5. ��������� ������� ������� �� ������� ��������
% -- ������� ������ ������ ������� �������� �� ���������
aMeanIntensitiesByClusters=zeros(1, ikIntensitiesLength);
% -- ��������� � ���������� ������� ������� � ������ ��������
for i=1:1:ikIntensitiesLength
    % ���� ������ ������� ��������� "0-��", �� ��������� ��������� ��������� �� "0-��"
    if(i==1 && aFrequences(i)==0)
        bFlag=true;
        j=i;
        while(bFlag==true)
            %��������:
             if(j==ikIntensitiesLength+1)
                 msgbox('1.5.: Error! Image is blank. Array of frequences aFrequences is empty. EXITING program!');
                 return;
             end;
            if(aClusters(j)==1 && aFrequences(j)~=0)
                aMeanIntensitiesByClusters(i)=aIntensities(j);
                bFlag=false;
            end;
            j=j+1;
        end;
    end;
    % ���� ��������� �� "0-��" �������, �� �������� ������� ��������
    if(aFrequences(i)~=0)
        aMeanIntensitiesByClusters(i)=aIntensities(i);
    end;
    % ���� ��������� ������� ����������� "0-��", �� ����������� �� ���������� 
    if(i>1 && aFrequences(i)==0)
        aMeanIntensitiesByClusters(i)=aMeanIntensitiesByClusters(i-1);
    end;
end;

%1.6 ��������� dE 
%(����������� ������ ����������� � ���, ��� ���������� ����� ���������� 
%�������������� ����� ���������� ��������� ������������ ������. 
%
% ���������� ����� ����������� ������� ���������� ����� ������ �������
% ����������
% -- ������� ������ ������ �������� ���.��.���������� �� ������� ��������
adE=zeros(1,ikIntensitiesLength);
% -- ��������� ���������� ���.��.���������� dE
for i=1:1:ikIntensitiesLength
    %����� �������� dE ��� ������ ������ ������� ��������
    if(aClusters(i)==1)
        adE(i)=-1; 
    end;
    %����� �������� dE ��� ������� ������ ���� ����.-���.��.
    if(aClusters(i)~=1 && aFrequences(i)~=0)
        n1=aNumberOfPixelsInClusters(i-1); 
        n2=aNumberOfPixelsInClusters(i);
        I1=aMeanIntensitiesByClusters(i-1); 
        I2=aMeanIntensitiesByClusters(i);
        adE(i)=n1*n2/(n1+n2)*(I1-I2)^2;
    end;
    %����� ������������� dE ���� ��������� ������ �������� 
    if(aClusters(i)~=1 && aFrequences(i)==0)
        adE(i)=adE(i-1);
    end;
end;
% ��������: 
for i=1:1:ikIntensitiesLength
    % �������� 0 ������ ������������ � ������� adE ����� ��� ����������
    if (adE(i)==0)
        msgbox('1.6. Error: Array of distances between adjacent clusters adE contain 0 value! EXITING program.');
        return;
    end;
    % �������� -1 ������ ���� ������ ��� ������� ��������
    if (adE(i)==-1 && aClusters(i)>1)
        msgbox('1.6. Error: Distance value of -1 appropriate for first cluster was set to one of the next clusters! EXITING program.');
        return;        
    end;
end;

%%����������������� ��� ������ � �������������
%% -- -- ��������� ������ ��������� � ��������� �����
fileNameNew=strcat(num2str(iIntensitiesNumOfNonEmpty),'_',num2str(0.0000),'.png');
pathToFileNew=fullfile(pathToFolderNew, fileNameNew);
imwrite(imgGS, pathToFileNew);

% 1.7. ����������� "����������� ����" ��������� 
% (����� ���� ��������, ������� �������������� ����������� ���������� ���.��.����.)
% ���������� ����� ���������� ���� � ����������� �����������  
idEmin=999999999999999; 
% ���������� iPairWith_min_dE ��������� �� �������, ������� �������� �
% ���������� "����������� ����". � �������� ���� ��������� �� �������� ������ ���� ������ 0. 
iPairWith_min_dE=0; 
for i=1:1:ikIntensitiesLength
    if(adE(i)~=-1 && adE(i)<idEmin)
        idEmin=adE(i);
        iPairWith_min_dE=aClusters(i);
    end;
end;
%��������:
if (idEmin==999999999999999 || iPairWith_min_dE==0)
        msgbox('1.7. No "minimal pairs" has been found! Input image consists of one cluster. EXITING program.');
        return;
end;

%(����������� ������ � ���, ��� ������� ����������� �������� ���������
%����� ������� �������� ���������) 
%1.8 ������� ���������� 1 ��� ������� �������� ��������� 
% -- ������� ������� ������� ��������� �������� ���������� 1 (����� ���������)
aSummand1=zeros(1,ikIntensitiesLength);
% -- ���������� ������� ���������� 1
for i=1:1:ikIntensitiesLength
    %���� ������ ������� ������� �������� "�������", �� ����� �� "�������"
    %������� � �������� � ��������� ��������� 1
    if(i==1 && aFrequences(i)==0)
        bFlag=true;
        j=i;
        while(bFlag==true)
            %��������:
             if(j==ikIntensitiesLength+1)
                 msgbox('1.8.: Error! Image is blank! Summand1 has not collected any data. EXITING program!');
                 return;
             end;
            if(aClusters(j)==1 && aFrequences(j)~=0)
                aSummand1(i)=aFrequences(j)*(aIntensities(j))^2;
                bFlag=false;
            end;
            j=j+1;
        end;
    end;
    %���� ��������� ������� � �������� "�������", �� ����������� ��������
    %���������� 1 �� ���������� ������� 
    if(i>1 && aFrequences(i)==0)
        aSummand1(i)=aSummand1(i-1);
    end;
    %���� ��������� ��������� ������� �� "0-��", �� ��������� ���������
    if (i>1 && aFrequences(i)~=0)
        aSummand1(i)=aFrequences(i)*(aIntensities(i))^2;
    end;
    %���� ��� ��������� ������� � �������� � ������ ��������� ����� (0 �������), �� ����������� � ����������
    %��������:
    for j=2:1:ikIntensitiesLength
        if (j>1 && aClusters(j)~=aClusters(j-1) && aFrequences(j)==0)
            sMessage=strcat('1.8. Error! Cluster '+num2str(aClusters(j))+' contain 0 pixels. EXITING program.');
            msgbox(sMessage);
            return;
        end;
    end;
end;

%1.9 ������� ���������� 2 ��� ������� �������� ��������� 
% -- ������� ������� ������� ��������� �������� ���������� 2 (������� �����)
aSummand2=zeros(1,ikIntensitiesLength);
% -- ���������� ������� ���������� 2
for i=1:1:ikIntensitiesLength
    %���� ������ ������� "0-��", �� ����� �� "0-�" ������� � �������� �
    %��������� ��������� 2
    if(i==1 && aFrequences(i)==0)
        bFlag=true;
        j=i;
        while(bFlag==true)
            %��������:
             if(j==ikIntensitiesLength+1)
                 msgbox('1.9.: Error! Image is blank! Summand2 has not collected any data. EXITING program!');
                 return;
             end;
            if(aClusters(j)==1 && aFrequences(j)~=0)
                aSummand2(i)=( aIntensities(j)*aFrequences(j) )^2 / aNumberOfPixelsInClusters(i);
                bFlag=false;
            end;
            j=j+1;
        end;
    end;
    %���� ��������� ��������� ������� �� "0-��", �� ��������� ���������
    if (i>1 && aFrequences(i)~=0)
        aSummand2(i)=( aIntensities(i)*aFrequences(i) )^2 / aNumberOfPixelsInClusters(i);
    end;
    %���� ��������� ������� � �������� � ������ ��������� ����� (0 �������), �� ����������� � ����������
    if (i>1 && aFrequences(i)==0)
        aSummand2(i)=aSummand2(i-1);
    end;
end;

%1.10 C�������� �������� ������� "� �� ��������" �� ������� ("��������")
% -- ������� ������ ������ "� �� ��������" 
aE_byColumn=zeros(1,ikIntensitiesLength);
% -- ����� ������� ��������� 1 � 2 � �������� �������� � ������ "� �� ��������"
 for i=1:1:ikIntensitiesLength 
     aE_byColumn(i)=aSummand1(i)-aSummand2(i);
 end;
%��������:
% �� ��������������� ���� ������� ������ ���������� �������, ����� - ������.
 for i=1:1:ikIntensitiesLength 
     if(aE_byColumn(i)~=0)
         msgbox('1.10. Error! Array aE_byColumn must contain only zeros at preliminary step. Otherwise it means that summands which difference is calculated are not equal. EXITING program');
         return;
     end;
 end;

%1.11 ��������� "� �� ���������"
% -- ������� ������ ������ "� �� ���������" 
aE_byClusters=zeros(1,ikIntensitiesLength);
for i=1:1:ikIntensitiesLength
    % -- ���� ������ ������ � ������� "E �� ��������", �� ����������� �� �������� � ������ "E �� ���������"
    if(i==1)
        aE_byClusters(i)=aE_byColumn(i);
    end;
    % -- ���� ��������� ������ ������ � ��������, �� ����������� �� �������� � ������ "� ��
    % ��������"
    if(i>1 && aClusters(i)~=aClusters(i-1))
        aE_byClusters(i)=aE_byColumn(i);
    end;
    % -- �������� ���� � ��������� ������ 
    if(i>1 && aClusters(i)==aClusters(i-1))
        aE_byClusters(i)=0;
    end;
end;
%��������:
% �� ��������������� ���� ������ "E �� ���������" ������ �������� ����, ����� - ������.
 for i=1:1:ikIntensitiesLength 
     if(aE_byClusters(i)~=0)
         msgbox('1.11. Error! Array aE_byClusters must contain only zeros at preliminary step. EXITING program');
         return;
     end;
 end;

%1.12. ��������� iEtotal 
% -- ������� ���������� iEtotal, ���������� ������ �������������,
% ��������������� �������� �������� ��������� �� ��������
iEtotal=0;
iEtotalPreviousPartition=0;
% -- �������������� iEtotal ��� ������� �������� �������� ��������� �� ��������
for i=1:1:ikIntensitiesLength
    % -- ���� ������ ������ � ������� "E �� ���������", �� ��������������
    if(i==1)
        iEtotal=iEtotal+aE_byClusters(i);
    end;
    % -- ���� ��������� ������ ������� "� �� ���������" ������ � ��������, �� ��������������, ����� ����������.
    if(i>1 && aClusters(i)~=aClusters(i-1))
        iEtotal=iEtotal+aE_byClusters(i);
    end;
end;
%��������:
% �� ��������������� ���� ���������� iEtotal ������ �������� ����, ����� - ������.
 for i=1:1:ikIntensitiesLength 
     if(iEtotal~=0)
         msgbox('1.12. Error! Variable iEtotal must contain zero at preliminary step. EXITING program');
         return;
     end;
 end;

 % 1.13. �������, �������� �������� ���.��.��. � ����� ��� �������
 % ��������� 
%-- ������ ������� c���� (root mean squared error)
aSigmaValues=zeros(1, iIntensitiesNumOfNonEmpty);
aSigmaIndex=zeros(1, iIntensitiesNumOfNonEmpty);
%-- ��������� ������� ������ ������ ������� ��� c���� (root mean squared
%error): ����� iIntensitiesNumOfNonEmpty "��������" ��������, �� ��������
%iIntensitiesNumOfNonEmpty-1 �������� �� �����������. �������� �������
%������ � ������ ��� ����, ����� ������ �������� ��������.
aSigmaIndex(iIntensitiesNumOfNonEmpty)=iIntensitiesNumOfNonEmpty-1;
% --  ������ ������ ��� � (���.��.��.)
aEValue=zeros(1, iIntensitiesNumOfNonEmpty);
aEIndex=zeros(1, iIntensitiesNumOfNonEmpty);
%-- ������ �������� ������� �������� � ������ ���.��.��. ���������� ������� ��� �����
aEIndex(iIntensitiesNumOfNonEmpty)=iIntensitiesNumOfNonEmpty-1;
%��������:
for i=1:1:ikIntensitiesLength
    if(i>=1 && i< iIntensitiesNumOfNonEmpty && aSigmaIndex(i)~=0)
        msgbox('1.13. Error! Wrong value in array aSigmaIndex. It must contain zeros overall except one value at last cell. EXITING program.');
        return;
    end;
    if(i==iIntensitiesNumOfNonEmpty && aSigmaIndex(i)==0)
        msgbox('1.13. Error! Wrong value in array aSigmaIndex. Last cell must contain value which is not zero. EXITING program.');
        return;
    end;
    if(i>=1 && i< iIntensitiesNumOfNonEmpty && aEIndex(i)~=0)
        msgbox('1.13. Error! Wrong value in array aEIndex. It must contain zeros overall except one value at last cell. EXITING program.');
        return;
    end;
    if(i==iIntensitiesNumOfNonEmpty && aEIndex(i)==0)
        msgbox('1.13. Error! Wrong value in array aEIndex. Last cell must contain value which is not zero. EXITING program.');
        return;
    end;
end;

%��������:
if(iIntensitiesNumOfNonEmpty<=2 && iIntensitiesNumOfNonEmpty>0)
     msgbox('pre 2]. Error! Variable iIntensitiesNumOfNonEmpty is equal or less than 2, but greater than 0. Main body of the program is not going to start. EXITING program');
     return;
end;

%UNCOMMENT to watch results of preliminary step
%iNumberOfClustersLeft
%aNumberOfPixelsInClusters
%aSummand1
%aE_byColumn
%aE_byClusters
%iEtotal
%aEValue

% 2] ����������� ����������� ��� ���������.
for k=iIntensitiesNumOfNonEmpty:-1:2
    %��������
    if(iPairWith_min_dE==0)
        msgbox('2] Variable iPairWith_min_dE==0. This check MUST NOT execute. Variable iPairWith_min_dE must be equal 1 or greater. Otherwise program went bad totally! Uncomment test arrays and trace program.');
        return;
    end;
    
    % 2.1) �����. ���. � ���� �����. ��. � ������������� ���� ������. ��. 
    for i=1:1:ikIntensitiesLength
        % -- 2.1) ����������� �������� � ���� �������: ������� ������� � ����������� (������������) �������� 
        if(aClusters(i)==iPairWith_min_dE)
            aClusters(i)=aClusters(i)-1;
        end;
        % -- 2.2) ������������� ���� ������. ��-���:
        if(aClusters(i)>iPairWith_min_dE)
            aClusters(i)=aClusters(i)-1;
        end;
    end;
    iClusterUnited=iPairWith_min_dE-1; % iClusterUnited - ����� ��������, ������� ���������;  
    iNumberOfClustersLeft=iNumberOfClustersLeft-1;
    %��������:
    if (iClusterUnited<1 || iClusterUnited>iNumberOfClustersLeft)
        sMessage=strcat('2.2)Variable iClusterUnited is out of range [1,'+ num2str(iNumberOfClustersLeft)+']. EXITING program.');
        msgbox(sMessage);
        return;
    end;
    
    %2.3) ������� ����� ����. n � �����.��.
    iSumOfPixelsInCluster=0;
    for i=1:1:ikIntensitiesLength
        if(aClusters(i)==iClusterUnited)
            iSumOfPixelsInCluster=iSumOfPixelsInCluster+aFrequences(i);
        end;
         if(aClusters(i)>iClusterUnited)
             break;
         end;
    end;
    %��������:
    if (iSumOfPixelsInCluster==iNumberOfPixelsTotal && iNumberOfClustersLeft>1)
        msgbox('2.3)Error: iNumberOfClustersLeft>1. All pixels are collected in one sole cluster, but variable iNumberOfClustersLeft indicate that there are more than 1 cluster. EXITING program.');
        return;
    end;
    
    %2.4) ������ �������� n �� ��� ������ �����.��.
    for i=1:1:ikIntensitiesLength
        if(aClusters(i)==iClusterUnited)
            aNumberOfPixelsInClusters(i)=iSumOfPixelsInCluster;
        end;
        if(aClusters(i)>iClusterUnited)
             break;
         end;
    end;
    
    %2.5) ������ ����.�����.���. I � ������.��.
    iIntensitySummarized=0;
    for i=1:1:ikIntensitiesLength
        if(aClusters(i)==iClusterUnited)
            iIntensitySummarized=iIntensitySummarized+aIntensities(i)*aFrequences(i);
        end;
        if(aClusters(i)>iClusterUnited)
             break;
         end;
    end;
    %(����������� ���������� 2024 ����) ROUND intensity value only in step
    %of generating partition to load it on hard drive
    iMeanIntensityInCluster=iIntensitySummarized/iSumOfPixelsInCluster;
    
    %2.6) ������ �������� I �� ��� ������ ������.��.
    for i=1:1:ikIntensitiesLength
        if(aClusters(i)==iClusterUnited)
            aMeanIntensitiesByClusters(i)=iMeanIntensityInCluster;
        end;
        if(aClusters(i)>iClusterUnited)
             break;
        end;
    end;
    
    % 2.7) (������� �� ����� else: ������ ��.) ������� dE ��� ���� ����.-���.��. 
    % (� ������ ������� �������� ����������� �������� dE=-1) 
    if(iClusterUnited>1)
        for i=2:1:ikIntensitiesLength
            if(aClusters(i-1)==aClusters(i) && aClusters(i)==iClusterUnited)
                break;
            end;
            if(aClusters(i)==iClusterUnited)
                n1=aNumberOfPixelsInClusters(i-1); 
                n2=aNumberOfPixelsInClusters(i);
                I1=aMeanIntensitiesByClusters(i-1); 
                I2=aMeanIntensitiesByClusters(i);
                idE= n1*n2/(n1+n2) *(I1-I2)^2;
            end;
        end;
    else
        idE=-1;
    end;
    
    % 2.8) ������ ��.dE � ������ ���.��. 
    for i=1:1:ikIntensitiesLength
        if(aClusters(i)==iClusterUnited)
            adE(i)=idE;
        end;
        if(aClusters(i)>iClusterUnited)
            break;
        end;
    end;
    
    % 2.9) ������� dE ��� ���� ���.-����.��.
    if(iClusterUnited+1<=iNumberOfClustersLeft)
        for i=2:1:ikIntensitiesLength
            if((aClusters(i-1)==iClusterUnited+1) && (aClusters(i)==iClusterUnited+1))
                break;
            end;
            if((aClusters(i-1)==iClusterUnited+1) && (aClusters(i)>iClusterUnited+1))
                break;
            end;
            if(aClusters(i)==iClusterUnited+1)
                n1=aNumberOfPixelsInClusters(i-1); 
                n2=aNumberOfPixelsInClusters(i);
                I1=aMeanIntensitiesByClusters(i-1); 
                I2=aMeanIntensitiesByClusters(i);
                idE=n1*n2/(n1+n2)*(I1-I2)^2;
            end;
        end;
    end;
    %��������:
    if(iClusterUnited>iNumberOfClustersLeft)%iClusterUnited+1
        msgbox('2.9. Error in cluster counting: iClusterUnited+1>iNumberOfClustersLeft. Variable "iClusterUnited+1" must be <= iNumberOfClustersLeft. EXITING program');
        return;
    end;
        
    % 2.10) ������ �������� dE �� ��� ������ ����.��.
    % (�������: ���� ������� � ����.��.)
    if(iClusterUnited+1<=iNumberOfClustersLeft)
        for i=1:1:ikIntensitiesLength
            if(aClusters(i)>iClusterUnited+1)
                break;
            end;
            if(aClusters(i)==iClusterUnited+1)
                adE(i)=idE;
            end;
        end;
    end;
    
    % 2.11) ����� ��������� "����������� ����" dE=min>0
    idEmin=999999999999999; 
    iPairWith_min_dE=0;
    for i=1:1:ikIntensitiesLength
        if(adE(i)~=-1 && adE(i)<idEmin)
            idEmin=adE(i);
            iPairWith_min_dE=aClusters(i);
        end;
    end;
        
    %2.12) ������ ���������� 1 � 2.13) ��� ������
    for i=1:1:ikIntensitiesLength
        %��������� ����������� ������� ����� ���������� �������� ������� �
        %������������ �������� ��� ���������� 1.
        if(aClusters(i)>iClusterUnited)
            break;
        end;
        iSummand1=0;
        %��� ������ ������� ������� �������� ���������
        if(i==1 && aClusters(i)==1)
            for j=1:1:ikIntensitiesLength
                if(aClusters(j)~=1)
                    break;
                end;
                iSummand1=iSummand1+(aIntensities(j)^2)*aFrequences(j);
            end;
            aSummand1(i)=iSummand1;
        end;
        %��� ��������� ������� � �������� ����������� ��������
        if(i>1 && aClusters(i)==aClusters(i-1))
            aSummand1(i)=aSummand1(i-1);
        end;
        %��� ������ ������� ���������� �������� ���������
        iSummand1=0;
        if(i>1 && aClusters(i)~=aClusters(i-1) && aClusters(i)==iClusterUnited )
            for j=i:1:ikIntensitiesLength
                if(aClusters(j)~=iClusterUnited)
                    break;
                end;
                iSummand1=iSummand1+(aIntensities(j)^2)*aFrequences(j);
            end;
            aSummand1(i)=iSummand1;
        end;
    end;
    
    %2.14) ������� ���������� 2 � 2.15) ��� ������
    for i=1:1:ikIntensitiesLength
        %��������� ����������� ������� ����� ���������� �������� ������� �
        %������������ �������� ��� c��������� 2.
        if(aClusters(i)>iClusterUnited)
            break;
        end;
        dSummand2=0;
        %��� ������ ������� ������� �������� ���������
        if(i==1 && aClusters(i)==1)
            for j=1:1:ikIntensitiesLength
                if(aClusters(j)~=1)
                    break;
                end;
                dSummand2=dSummand2+aIntensities(j)*aFrequences(j);
            end;
            aSummand2(i)=(dSummand2^2)/aNumberOfPixelsInClusters(i);
        end;
        %��� ������ ������� ���������� �������� ���������
        dSummand2=0;
        if(i>1 && aClusters(i)~=aClusters(i-1) && aClusters(i)==iClusterUnited )
            for j=i:1:ikIntensitiesLength
                if(aClusters(j)~=iClusterUnited)
                    break;
                end;
                dSummand2=dSummand2+aIntensities(j)*aFrequences(j);
            end;
            aSummand2(i)=(dSummand2^2)/aNumberOfPixelsInClusters(i);
        end;
        %��� ��������� ������� � �������� ����������� ��������
        if(i>1 && aClusters(i)==aClusters(i-1))
            aSummand2(i)=aSummand2(i-1);
        end;
    end;
 
    %2.16) ������� � �� ���������
    for i=1:1:ikIntensitiesLength
        %��������� ������ �� ������� ����� ��������� ����������� ��������
        if(aClusters(i)>iClusterUnited)
            break;
        end;
        %����� ������������ ������� � ��������� ��� ������ ������� �������
        %���������� 1 � ���������� 2
        if(aClusters(i)==iClusterUnited)
            aE_byColumn(i)=aSummand1(i)-aSummand2(i);
        end;
    end;
    
    %2.17) � 2.18) ���������� ������� "� �� ���������"
    %������ ������� �������� �� "� �� ��������� " � ������ "� �� ���������"
    %������ 0 �� ��� ������ ������� "� �� ���������" ��� ��.1
    for i=1:1:ikIntensitiesLength
        if(aClusters(i)>iClusterUnited)
            break;
        end;
        %���� ������������ ������� - ������ ������� � �������, ��
        %����������� �������� �� ������ �������
        if(i==1 && aClusters(i)==iClusterUnited)
            aE_byClusters(i)=aE_byColumn(i);
        end;
        %��� ��������� ������ ������������� �������� �������� 0
        if(i>1 && aClusters(i)==iClusterUnited && aClusters(i-1)==aClusters(i))
            aE_byClusters(i)=0;
        end;
        %��� ������ ������ ���������� �������� �������� ������ ��������
        if(i>1 && aClusters(i)==iClusterUnited && aClusters(i-1)~=aClusters(i))
            aE_byClusters(i)=aE_byColumn(i);
        end;
    end;
    
    %2.19) ��������� Etotal, ������������� ������ ������� 
%     iEtotal=0;
%     for i=1:1:ikIntensitiesLength
%         iEtotal=iEtotal+aE_byClusters(i);
%     end;
    %2.20) �������� Etotal: ����� �� ������ ������� ���������
    iEtotal=0;
    for i=1:1:ikIntensitiesLength
        %������ ������ ������� �������� � ������� ���������
        if( (i==1 && aClusters(i)==iClusterUnited) || (i==1 && ikIntensitiesLength>1 && aClusters(i)==aClusters(i+1)))
            iEtotal=iEtotal+aE_byClusters(i); % ����� aE_byColumn(i)
        end;
        if(ikIntensitiesLength==1)
            msgbox('2.20) Error: ikIntensitiesLength==1. Image consists of one intensity or one cluster. EXITING program.');
            return;
        end;
        %������ ������ ���������� �������� ���������
        if(i>1 && aClusters(i-1)~=aClusters(i))
            iEtotal=iEtotal+aE_byClusters(i);% ����� aE_byColumn(i)
        end;
    end;
    %��������:
    if (iEtotal<iEtotalPreviousPartition)
        msgbox('2.20) Error: iEtotal<iEtotalPreviousPartition. Approximation error of current partition is less than approximation error of previous partition. EXITING program.');
        return;
    end;
    
    % 2.21)��������� � ��������� � ������� �������� ���������
    % ����� ����������� ��� ������ ������� �� �����
    %-- ��������� ����� 
    iSigma=sqrt(iEtotal/numOfRows/numOfCols); % ������ iSigma
    %-- ��������� ����� � ������� �� ��������������� ������� ������� � ������� ����.
    aSigmaValues(k-1)=iSigma; 
    %-- ���������� ���������� ����� ��������� ��� �����
    aSigmaIndex(iIntensitiesNumOfNonEmpty-k+1)=iIntensitiesNumOfNonEmpty-k;
    %-- ����������� �������� iEtotal �������� ��������� � ������ aEValue
    aEValue(k-1)=iEtotal;
    %-- ���������� ���������� ����� ��������� ��� ���.��.��.
    aEIndex(iIntensitiesNumOfNonEmpty-k+1)=iIntensitiesNumOfNonEmpty-k;
    %-- ��������� �������� � (���.��.��.) ��� ������� ��� ��������� � ����� ������� ��������� 
    iEtotalPreviousPartition=iEtotal;
    
    %����������������� ������� 2.22, 2.23 ��� ������ � �������������
    %2.22) ������������ ���������
    imgPartition=imgGS;
    grayNew=0;
    for i=1:1:numOfRows
        for j=1:1:numOfCols
            grayOld=imgGS(i,j,1);
            grayNew=aMeanIntensitiesByClusters(1,grayOld+1);
            imgPartition(i,j,1)=grayNew;
            imgPartition(i,j,2)=grayNew;
            imgPartition(i,j,3)=grayNew;
        end;
    end;
    
    %2.23) ���������� �������� ��������� � ������
    fileNameNew=strcat(num2str(iNumberOfClustersLeft),'_',num2str(iSigma),'.png');
    if  isempty(fileNameNew)
        msgbox('2.23) Error! String variable "fileNameNew" is empty. No file name is specified to save partition. EXITING program.');
        return;
    end;
    pathToFileNew=fullfile(pathToFolderNew, fileNameNew);
    if  isempty(pathToFileNew)
        msgbox('2.23) Error! String variable "pathToFileNew" is empty. No path to file is specified to save partition. EXITING program.');
        return;
    else
        imwrite(imgPartition, pathToFileNew);
    end;
    
  
    % UNCOMMENT to watch process of chances in output
    %iNumberOfClustersLeft
    %aNumberOfPixelsInClusters
    %aClusters
    %adE
    %iPairWith_min_dE
    %aSummand1
    %aSummand2
    %aE_byColumn
    %aE_byClusters
    %iEtotal
    %aEValue
    %aSigmaValue
    

end;

%%����������������� ������ 3 ��� ������ � �������������
%3] ���������� ���������
% 3.1) ���������� ������ ����� ��� ����� ���������
% -- ����� � ���������� ��������� ������� ����� ��� ����� ���������
figure('Name', 'Linear Plot of Sigma Values of Partition Sequence','NumberTitle','off'), plot(aSigmaIndex, aSigmaValues, 'b-', 'LineWidth', 2), grid on;
xlabel('Number of Partition, N');
ylabel('Sigma Values, Sigma');
fileNameNew='SigmaPlot_Linear.png';
pathToFileNew=fullfile(pathToFolderNew, fileNameNew);
if isempty(pathToFileNew)
    msgbox('3.1) Error! String variable "pathToFileNew" is empty. No path to file is specified to save linear sigma plot. EXITING program.');
    return;
else
    saveas(gcf, pathToFileNew);
end;
% -- ����� � ���������� ���������������� ������� ����� ��� ����� ���������
% -- -- ������ ���� �� ������������ ��������, ����� ������ ������ �
% �������������
aSigmaValues(iIntensitiesNumOfNonEmpty)=0.001;
figure('Name', 'Logarithmic Plot of Sigma Values of Partition Sequence','NumberTitle','off'), loglog(aSigmaIndex, aSigmaValues, 'b-', 'LineWidth', 2), grid on;
xlabel('Number of Partition, N');
ylabel('Sigma Values, Sigma');
fileNameNew='SigmaPlot_Log.png';
pathToFileNew=fullfile(pathToFolderNew, fileNameNew);
if isempty(pathToFileNew)
    msgbox('3.1) Error! String variable "pathToFileNew" is empty. No path to file is specified to save linear sigma plot. EXITING program.');
    return;
else
    saveas(gcf, pathToFileNew);
end;

