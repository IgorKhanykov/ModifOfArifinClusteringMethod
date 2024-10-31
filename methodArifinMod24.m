%Программа (листинг программного кода) реализации алгломеративной 
%кластеризации пикселей изображений из оттенков серого на основе метода 
%Арифина с модификацией расчета расстояния между парами смежных кластеров и 
%обеспечением расчета качества разбиения на кластеры. Расстояние между 
%кластерами расчитывается через формулу минимума приращения суммарной 
%квадратичной ошибки. Качество текущего разбиения на кластеры вычисляется 
%через разностную формулу.

% автор: м.н.с. кафедры 23 ГУАП Ханыков И.Г.  
% дата начала программирования:     22-07-2024
% дата окончания программирования:  02-08-2024
% дата(-ы) внесения правок:         



%%Затереть комментарий в коне разработки:  
%% Переименование переменных: iIntensitiesLength --> ikIntensitiesLength
%%

% %ЗАГРУЗКА ИЗОБРАЖЕНИЯ (раздел программы 0]) ЗАКОМЕНТИРОВАНА НА МАССИВЫ (раздел 1]) НА ВРЕМЯ РАЗРАБОТКИ И ОТЛАДКИ ПРОГРАММЫ
% % 0] загрузить и подготовить изображение
% % -- 0.1) считать выбранное изображение 
[fileName, pathToFolder]=uigetfile({'*.png'},'Select png-image...');
pathToFile=fullfile(pathToFolder, fileName);
if( size(pathToFile,2)==3)
    msgbox('Empty file path! Select image. EXITING program!');
    return;
end;
img=imread(pathToFile);
figure('Name', 'Input Image','NumberTitle','off'), imshow(img);

% -- 0.2) создать пустую папку по адресу выбранного изображения
splitedString = strsplit(fileName,'.');
fileTitle=char(splitedString(1));
pathToFolderNew=fullfile(pathToFolder,fileTitle);
if ~exist(pathToFolderNew, 'dir')
    mkdir(pathToFolderNew);
else
    msgbox('Destination folder already exists! Rename folder or image file and try again. EXITING parogram!');
    return;
end;

% -- 0.3) проверить количество цветовых каналов и в случае загрузки 
% цветного изображения перевести его в оттенки серого
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
        %Здесь должна быть проверка цвета в изображении, но решил без нее.
        %В любом случае конвертировал в оттенки серого. В конце программы
        %переменная iNumOfChannels нужна для выбора типа изображения для
        %сохранения: 8-битное (1 канал) или 24-битное (3 канала).
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

% 1] создать базовые массивы.
%1.1 создать массив яркостей, 
% % aIntensities=   [100,101,102,103,104,105,106,107,108,109,110]; % шкала яркостей
% % ikIntensitiesLength=size(aIntensities,2);          % всего яркостей
% !!ЗАКОММЕНТИРОВАТЬ верхние строки и РАCКОММЕНТИРОВАТЬ нижние при работе с
% реальным изображением
ikIntensitiesLength=256;
aIntensities=zeros(1,ikIntensitiesLength);
for i=1:1:256
    aIntensities(i)=i-1;
end;

%1.2 создать и заполнить массив частот
% гистограмма изображения из оттенков серого
% % aFrequences=[0,1,4,8,10,5,0,0,15,3,0];          % гистограмма частот яркостей
% % iNumberOfPixelsTotal=0;     % всего пикселей
% % for i=1:1:ikIntensitiesLength
% %     iNumberOfPixelsTotal=iNumberOfPixelsTotal+aFrequences(i);
% % end;
% !!ЗАКОММЕНТИРОВАТЬ верхние строки и РАCКОММЕНТИРОВАТЬ нижние при работе с
% реальным изображением
figHistBars=figure('Name', 'Histogram of the Grayscale Image','NumberTitle','off'), ImageHistogram=histogram(imgGS(:,:,1),256), grid;
xlabel('Order Number of Gray Intensity');
ylabel('Quantity of Each Intensity');
% -- сохранить гистограмму
fileNameNew='ImageHistogram.png';
pathToFileNew=fullfile(pathToFolderNew, fileNameNew);
if isempty(pathToFileNew)
    msgbox('1.2) Error! String variable "pathToFileNew" is empty. No path to file is specified to save histogram. EXITING program.');
    return;
else
    saveas(figHistBars, pathToFileNew);%gcf
end;
aFrequences=ImageHistogram.Values;

% -- пересчитать количество не "нулевых яркостей" (яркости с частотой больше 0)
iIntensitiesNumOfNonEmpty=0;
for i=1:1:ikIntensitiesLength
    if(aFrequences(i)~=0)
        iIntensitiesNumOfNonEmpty=iIntensitiesNumOfNonEmpty+1;
    end;
end;
% ПРОВЕРКА
% -- если только "нулевые яркости" в изображении (изображение, гистограмма которого пустая)
if(iIntensitiesNumOfNonEmpty==0)
    msgbox('1.2.Image is blank! Variable iIntensitiesNumOfNonEmpty must be grater than 0 for the image. EXITING program!');
    return;
end;


%1.3 перенумеровать кластеры. 
% -- создать пустой массив кластеров
aClusters=zeros(1,ikIntensitiesLength);
% -- перенумеровать кластеры (одна яркость - один кластер, но 
%"нулевые яркости" не образуют кластер)
% Если первая яркость "нулевая", то отнести к следующей не "нулевой"
% Если очередная яркость "нулевая", то отнести к предыдущей не "нулевой"
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
iNumberOfClustersTotal=k-1;   % число кластеров в изображении всего
iNumberOfClustersLeft=iNumberOfClustersTotal; % сколько кластеров осталось до объединения в один целый
%ПРОВЕРКА:
if(iNumberOfClustersTotal==1)
    msgbox('1.3. Number of clustes is equal 1! Image is plain. EXITING program.');
    return;
end;

% 1.4. Сосчитать число пикселей в каждом кластере
% -- создать пустой массив, хранящий число пикселей в каждом кластере
aNumberOfPixelsInClusters=zeros(1,ikIntensitiesLength);
% -- сосчитать и проставить число пикселей в каждом кластере.
iClusterToConsider=1;
iSumOfPixelsInCluster=0;
for i=1:1:ikIntensitiesLength
    % Для первой яркости в "многояркостном" кластере просчитать сумму пикселей по каждой яркости в крастере
    if(i<ikIntensitiesLength &&  aClusters(i)==iClusterToConsider && aClusters(i+1)==iClusterToConsider)
        bFlag=true;
        j=i;
        while(bFlag==true && j<=ikIntensitiesLength) % просуммировать пиксели по кластеру
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
        while(bFlag==true && j<=ikIntensitiesLength) % прописать сумму пикселей в кластере в колонке каждой яркости
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
    %Для "однояркостного" кластера в середине массива кластеров
    if(i<ikIntensitiesLength && aClusters(i)==iClusterToConsider && aClusters(i+1)==iClusterToConsider+1)
        aNumberOfPixelsInClusters(i)=aFrequences(i);
        iClusterToConsider=iClusterToConsider+1;
    end;
    %Для "однояркостного" кластера в конце массива кластеров  
    if(i==ikIntensitiesLength && aClusters(i)==iClusterToConsider && aClusters(i-1)==iClusterToConsider-1)
        aNumberOfPixelsInClusters(i)=aFrequences(i);
    end;
end;
% ПРОВЕРКА.  Значение "нуль" должно отсутсвовать в массиве
% aNumberOfPixelsInClusters. Минимальное число пикселей в кластере равно 1.
for i=1:1:ikIntensitiesLength
    if (aNumberOfPixelsInClusters(i)==0)
        sMessage=strcat('1.4. Error! Cluster '+num2str(aClusters(i))+' contain 0 pixels! EXITING program.');
        msgbox(sMessage);
        return;
    end;
end;

% 1.5. сосчитать среднюю яркость по каждому кластеру
% -- создать пустой массив средних яркостей по кластерам
aMeanIntensitiesByClusters=zeros(1, ikIntensitiesLength);
% -- сосчитать и проставить среднюю яркость в каждом кластере
for i=1:1:ikIntensitiesLength
    % если первая яркость оказалась "0-ой", то заполняем значением следующей не "0-ой"
    if(i==1 && aFrequences(i)==0)
        bFlag=true;
        j=i;
        while(bFlag==true)
            %ПРОВЕРКА:
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
    % если очередная не "0-ая" яркость, то записать текущее значение
    if(aFrequences(i)~=0)
        aMeanIntensitiesByClusters(i)=aIntensities(i);
    end;
    % если очередная яркость оказывается "0-ой", то скопировать от предыдущей 
    if(i>1 && aFrequences(i)==0)
        aMeanIntensitiesByClusters(i)=aMeanIntensitiesByClusters(i-1);
    end;
end;

%1.6 сосчитать dE 
%(МОДИФИКАЦИЯ метода заключается в том, что расстояние между кластерами 
%рассчитывается через приращение суммарной квадратичной ошибки. 
%
% фактически здесь выполняется рассчет расстояний между парами смежных
% класстеров
% -- создать пустой массив значений сум.кв.отклонения по каждому кластеру
adE=zeros(1,ikIntensitiesLength);
% -- сосчитать приращение сум.кв.отклонения dE
for i=1:1:ikIntensitiesLength
    %ЗДЕСЬ задается dE для первой клетки первого кластера
    if(aClusters(i)==1)
        adE(i)=-1; 
    end;
    %здесь задается dE для первоей клетки пары пред.-тек.кл.
    if(aClusters(i)~=1 && aFrequences(i)~=0)
        n1=aNumberOfPixelsInClusters(i-1); 
        n2=aNumberOfPixelsInClusters(i);
        I1=aMeanIntensitiesByClusters(i-1); 
        I2=aMeanIntensitiesByClusters(i);
        adE(i)=n1*n2/(n1+n2)*(I1-I2)^2;
    end;
    %здесь прописывается dE всех очередных клеток кластера 
    if(aClusters(i)~=1 && aFrequences(i)==0)
        adE(i)=adE(i-1);
    end;
end;
% ПРОВЕРКА: 
for i=1:1:ikIntensitiesLength
    % Значение 0 должно отсутсвовать в массиве adE после его заполнения
    if (adE(i)==0)
        msgbox('1.6. Error: Array of distances between adjacent clusters adE contain 0 value! EXITING program.');
        return;
    end;
    % Значение -1 должно быть только для первого кластера
    if (adE(i)==-1 && aClusters(i)>1)
        msgbox('1.6. Error: Distance value of -1 appropriate for first cluster was set to one of the next clusters! EXITING program.');
        return;        
    end;
end;

%%РАСКОММЕНТИРОВАТЬ при работе с изображениями
%% -- -- сохранить первое разбиение в созданную папку
fileNameNew=strcat(num2str(iIntensitiesNumOfNonEmpty),'_',num2str(0.0000),'.png');
pathToFileNew=fullfile(pathToFolderNew, fileNameNew);
imwrite(imgGS, pathToFileNew);

% 1.7. определение "минимальной пары" кластеров 
% (такой пары кластров, которая сопровождается минимальным приращеним сум.кв.откл.)
% фактически здесь выбирается пара с минимальным расстоянием  
idEmin=999999999999999; 
% переменаня iPairWith_min_dE указывает на кластер, который образует с
% предыдущим "минимальную пару". В основном теле программы ее значение должно быть больше 0. 
iPairWith_min_dE=0; 
for i=1:1:ikIntensitiesLength
    if(adE(i)~=-1 && adE(i)<idEmin)
        idEmin=adE(i);
        iPairWith_min_dE=aClusters(i);
    end;
end;
%ПРОВЕРКА:
if (idEmin==999999999999999 || iPairWith_min_dE==0)
        msgbox('1.7. No "minimal pairs" has been found! Input image consists of one cluster. EXITING program.');
        return;
end;

%(МОДИФИКАЦИЯ метода в том, что введено определение качества разбиения
%через формулу разности квадратов) 
%1.8 Рассчет слогаемого 1 для формулы разности квадратов 
% -- задание пустого массива хранящего значения слогаемого 1 (сумма квадратов)
aSummand1=zeros(1,ikIntensitiesLength);
% -- заполнение массива слогаемого 1
for i=1:1:ikIntensitiesLength
    %Если первая яркость первого кластера "нулевая", то найти не "нулевую"
    %яркость в кластере и сосчитать слогаемое 1
    if(i==1 && aFrequences(i)==0)
        bFlag=true;
        j=i;
        while(bFlag==true)
            %ПРОВЕРКА:
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
    %Если очередная яркость в кластере "нулевая", то скопировать значение
    %слогаемого 1 от предыдущей яркости 
    if(i>1 && aFrequences(i)==0)
        aSummand1(i)=aSummand1(i-1);
    end;
    %Если очередная отдельная яркость не "0-ая", то сосчитать слогаемое
    if (i>1 && aFrequences(i)~=0)
        aSummand1(i)=aFrequences(i)*(aIntensities(i))^2;
    end;
    %Если это очередная яркость в кластере и клетка слогамого пуста (0 записан), то скопировать с предыдущей
    %ПРОВЕРКА:
    for j=2:1:ikIntensitiesLength
        if (j>1 && aClusters(j)~=aClusters(j-1) && aFrequences(j)==0)
            sMessage=strcat('1.8. Error! Cluster '+num2str(aClusters(j))+' contain 0 pixels. EXITING program.');
            msgbox(sMessage);
            return;
        end;
    end;
end;

%1.9 рассчет слогаемого 2 для формулы разности квадратов 
% -- задание пустого массива хранящего значения слогаемого 2 (квадрат суммы)
aSummand2=zeros(1,ikIntensitiesLength);
% -- заполнение массива слогаемого 2
for i=1:1:ikIntensitiesLength
    %Если первая яркость "0-ая", то найти не "0-ю" яркость в кластере и
    %сосчитать слогаемое 2
    if(i==1 && aFrequences(i)==0)
        bFlag=true;
        j=i;
        while(bFlag==true)
            %ПРОВЕРКА:
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
    %Если очередная отдельная яркость не "0-ая", то сосчитать слогаемое
    if (i>1 && aFrequences(i)~=0)
        aSummand2(i)=( aIntensities(i)*aFrequences(i) )^2 / aNumberOfPixelsInClusters(i);
    end;
    %Если очередная яркость в кластере и клетка слогамого пуста (0 записан), то скопировать с предыдущей
    if (i>1 && aFrequences(i)==0)
        aSummand2(i)=aSummand2(i-1);
    end;
end;

%1.10 Cосчитать значения массива "Е по столбику" по клеткам ("встолбик")
% -- создать пустой массив "Е по столбику" 
aE_byColumn=zeros(1,ikIntensitiesLength);
% -- найти разницу слогаемых 1 и 2 и записать значение в массив "Е по столбику"
 for i=1:1:ikIntensitiesLength 
     aE_byColumn(i)=aSummand1(i)-aSummand2(i);
 end;
%ПРОВЕРКА:
% на предварительном шаге разница должна получаться нулевой, иначе - ошибка.
 for i=1:1:ikIntensitiesLength 
     if(aE_byColumn(i)~=0)
         msgbox('1.10. Error! Array aE_byColumn must contain only zeros at preliminary step. Otherwise it means that summands which difference is calculated are not equal. EXITING program');
         return;
     end;
 end;

%1.11 Сосчитать "Е по кластерам"
% -- создать пустой массив "Е по кластерам" 
aE_byClusters=zeros(1,ikIntensitiesLength);
for i=1:1:ikIntensitiesLength
    % -- Если клетка первая в массиве "E по столбику", то скопировать ее значение в массив "E по кластерам"
    if(i==1)
        aE_byClusters(i)=aE_byColumn(i);
    end;
    % -- Если очередная клетка первая в кластере, то скопировать ее значение в массив "Е по
    % кластеру"
    if(i>1 && aClusters(i)~=aClusters(i-1))
        aE_byClusters(i)=aE_byColumn(i);
    end;
    % -- Записать нули в остальные клетки 
    if(i>1 && aClusters(i)==aClusters(i-1))
        aE_byClusters(i)=0;
    end;
end;
%ПРОВЕРКА:
% на предварительном шаге массив "E по кластерам" должен содерать нули, иначе - ошибка.
 for i=1:1:ikIntensitiesLength 
     if(aE_byClusters(i)~=0)
         msgbox('1.11. Error! Array aE_byClusters must contain only zeros at preliminary step. EXITING program');
         return;
     end;
 end;

%1.12. Вычислить iEtotal 
% -- Создать переменную iEtotal, содержащую ошибки аппроксимации,
% характеризующую качество текущего разбиения на кластеры
iEtotal=0;
iEtotalPreviousPartition=0;
% -- Просуммировать iEtotal для расчета качества текущего разбиения на кластеры
for i=1:1:ikIntensitiesLength
    % -- Если клетка первая в массиве "E по кластерам", то просуммировать
    if(i==1)
        iEtotal=iEtotal+aE_byClusters(i);
    end;
    % -- Если очередная клетка массива "Е по кластерам" первая в кластере, то просуммировать, иначе пропустить.
    if(i>1 && aClusters(i)~=aClusters(i-1))
        iEtotal=iEtotal+aE_byClusters(i);
    end;
end;
%ПРОВЕРКА:
% на предварительном шаге переменная iEtotal должна содерать нуль, иначе - ошибка.
 for i=1:1:ikIntensitiesLength 
     if(iEtotal~=0)
         msgbox('1.12. Error! Variable iEtotal must contain zero at preliminary step. EXITING program');
         return;
     end;
 end;

 % 1.13. Массивы, хранящие значения сум.кв.ош. и сигмы для первого
 % разбиения 
%-- пустые массивы cигма (root mean squared error)
aSigmaValues=zeros(1, iIntensitiesNumOfNonEmpty);
aSigmaIndex=zeros(1, iIntensitiesNumOfNonEmpty);
%-- заполнить крайнюю правую ячейку массива для cигмы (root mean squared
%error): всего iIntensitiesNumOfNonEmpty "непустых" яркостей, но доступно
%iIntensitiesNumOfNonEmpty-1 операций по объединению. Обратный порядок
%записи в массив для того, чтобы график выглядил падающим.
aSigmaIndex(iIntensitiesNumOfNonEmpty)=iIntensitiesNumOfNonEmpty-1;
% --  пустой массив для Е (сум.кв.ош.)
aEValue=zeros(1, iIntensitiesNumOfNonEmpty);
aEIndex=zeros(1, iIntensitiesNumOfNonEmpty);
%-- запись крайнего правого значения в массив сум.кв.ош. аналогично массиву для сигма
aEIndex(iIntensitiesNumOfNonEmpty)=iIntensitiesNumOfNonEmpty-1;
%ПРОВЕРКА:
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

%ПРОВЕРКА:
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

% 2] итеративное объединение пар кластеров.
for k=iIntensitiesNumOfNonEmpty:-1:2
    %ПРОВЕРКА
    if(iPairWith_min_dE==0)
        msgbox('2] Variable iPairWith_min_dE==0. This check MUST NOT execute. Variable iPairWith_min_dE must be equal 1 or greater. Otherwise program went bad totally! Uncomment test arrays and trace program.');
        return;
    end;
    
    % 2.1) объед. ярк. в один укпур. кл. и перенумерация всех послед. кл. 
    for i=1:1:ikIntensitiesLength
        % -- 2.1) объединение яркостей в один кластер: яркости отнесли к предыдущему (укрупняемому) кластеру 
        if(aClusters(i)==iPairWith_min_dE)
            aClusters(i)=aClusters(i)-1;
        end;
        % -- 2.2) перенумерация всех послед. кл-ров:
        if(aClusters(i)>iPairWith_min_dE)
            aClusters(i)=aClusters(i)-1;
        end;
    end;
    iClusterUnited=iPairWith_min_dE-1; % iClusterUnited - номер кластера, который укрупнили;  
    iNumberOfClustersLeft=iNumberOfClustersLeft-1;
    %ПРОВЕРКА:
    if (iClusterUnited<1 || iClusterUnited>iNumberOfClustersLeft)
        sMessage=strcat('2.2)Variable iClusterUnited is out of range [1,'+ num2str(iNumberOfClustersLeft)+']. EXITING program.');
        msgbox(sMessage);
        return;
    end;
    
    %2.3) подсчет числа пикс. n в укруп.кл.
    iSumOfPixelsInCluster=0;
    for i=1:1:ikIntensitiesLength
        if(aClusters(i)==iClusterUnited)
            iSumOfPixelsInCluster=iSumOfPixelsInCluster+aFrequences(i);
        end;
         if(aClusters(i)>iClusterUnited)
             break;
         end;
    end;
    %ПРОВЕРКА:
    if (iSumOfPixelsInCluster==iNumberOfPixelsTotal && iNumberOfClustersLeft>1)
        msgbox('2.3)Error: iNumberOfClustersLeft>1. All pixels are collected in one sole cluster, but variable iNumberOfClustersLeft indicate that there are more than 1 cluster. EXITING program.');
        return;
    end;
    
    %2.4) запись значения n во все клетки укруп.кл.
    for i=1:1:ikIntensitiesLength
        if(aClusters(i)==iClusterUnited)
            aNumberOfPixelsInClusters(i)=iSumOfPixelsInCluster;
        end;
        if(aClusters(i)>iClusterUnited)
             break;
         end;
    end;
    
    %2.5) расчет знач.средн.ярк. I в укрупн.кл.
    iIntensitySummarized=0;
    for i=1:1:ikIntensitiesLength
        if(aClusters(i)==iClusterUnited)
            iIntensitySummarized=iIntensitySummarized+aIntensities(i)*aFrequences(i);
        end;
        if(aClusters(i)>iClusterUnited)
             break;
         end;
    end;
    %(МОДИФИКАЦИЯ уточняющая 2024 года) ROUND intensity value only in step
    %of generating partition to load it on hard drive
    iMeanIntensityInCluster=iIntensitySummarized/iSumOfPixelsInCluster;
    
    %2.6) запись значения I во все клетки укрупн.кл.
    for i=1:1:ikIntensitiesLength
        if(aClusters(i)==iClusterUnited)
            aMeanIntensitiesByClusters(i)=iMeanIntensityInCluster;
        end;
        if(aClusters(i)>iClusterUnited)
             break;
        end;
    end;
    
    % 2.7) (ПРОПУСК по ветке else: первый кл.) рассчет dE для пары пред.-тек.кл. 
    % (в случае первого кластера контрольное значение dE=-1) 
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
    
    % 2.8) Запись зн.dE в ячейки тек.кл. 
    for i=1:1:ikIntensitiesLength
        if(aClusters(i)==iClusterUnited)
            adE(i)=idE;
        end;
        if(aClusters(i)>iClusterUnited)
            break;
        end;
    end;
    
    % 2.9) Рассчет dE для пары тек.-след.кл.
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
    %ПРОВЕРКА:
    if(iClusterUnited>iNumberOfClustersLeft)%iClusterUnited+1
        msgbox('2.9. Error in cluster counting: iClusterUnited+1>iNumberOfClustersLeft. Variable "iClusterUnited+1" must be <= iNumberOfClustersLeft. EXITING program');
        return;
    end;
        
    % 2.10) запись значения dE во все клетки след.кл.
    % (ПРОПУСК: одна яркость в след.кл.)
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
    
    % 2.11) Выбор очередной "минимальной пары" dE=min>0
    idEmin=999999999999999; 
    iPairWith_min_dE=0;
    for i=1:1:ikIntensitiesLength
        if(adE(i)~=-1 && adE(i)<idEmin)
            idEmin=adE(i);
            iPairWith_min_dE=aClusters(i);
        end;
    end;
        
    %2.12) Расчет слогаемого 1 и 2.13) его запись
    for i=1:1:ikIntensitiesLength
        %перестать сканировать массивы ввиду завершения процесса расчета и
        %проставления значений для Слогаемого 1.
        if(aClusters(i)>iClusterUnited)
            break;
        end;
        iSummand1=0;
        %для первой яркости первого кластера сосчитать
        if(i==1 && aClusters(i)==1)
            for j=1:1:ikIntensitiesLength
                if(aClusters(j)~=1)
                    break;
                end;
                iSummand1=iSummand1+(aIntensities(j)^2)*aFrequences(j);
            end;
            aSummand1(i)=iSummand1;
        end;
        %для очередной яркости в кластере скопировать значение
        if(i>1 && aClusters(i)==aClusters(i-1))
            aSummand1(i)=aSummand1(i-1);
        end;
        %для первой яркости очередного кластера сосчитать
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
    
    %2.14) рассчет слогаемого 2 и 2.15) его запись
    for i=1:1:ikIntensitiesLength
        %перестать сканировать массивы ввиду завершения процесса расчета и
        %проставления значений для cлогаемого 2.
        if(aClusters(i)>iClusterUnited)
            break;
        end;
        dSummand2=0;
        %для первой яркости первого кластера сосчитать
        if(i==1 && aClusters(i)==1)
            for j=1:1:ikIntensitiesLength
                if(aClusters(j)~=1)
                    break;
                end;
                dSummand2=dSummand2+aIntensities(j)*aFrequences(j);
            end;
            aSummand2(i)=(dSummand2^2)/aNumberOfPixelsInClusters(i);
        end;
        %для первой яркости очередного кластера сосчитать
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
        %для очередной яркости в кластере скопировать значение
        if(i>1 && aClusters(i)==aClusters(i-1))
            aSummand2(i)=aSummand2(i-1);
        end;
    end;
 
    %2.16) рассчет Е по столбикам
    for i=1:1:ikIntensitiesLength
        %завершить проход по массиву ввиду окончания определения разности
        if(aClusters(i)>iClusterUnited)
            break;
        end;
        %найти объединенный кластер и сосчитать для каждой яркости разницу
        %слогаемого 1 и слогаемого 2
        if(aClusters(i)==iClusterUnited)
            aE_byColumn(i)=aSummand1(i)-aSummand2(i);
        end;
    end;
    
    %2.17) и 2.18) заполнение массива "Е по кластерам"
    %запись первого значения из "Е по столбикам " в массив "Е по кластерам"
    %запись 0 во все клетки массива "Е по кластерам" для кл.1
    for i=1:1:ikIntensitiesLength
        if(aClusters(i)>iClusterUnited)
            break;
        end;
        %Если объединенный кластер - первый кластер в массиве, то
        %скопировать значение от первой яркости
        if(i==1 && aClusters(i)==iClusterUnited)
            aE_byClusters(i)=aE_byColumn(i);
        end;
        %Для очередной клетки объединенного кластера записать 0
        if(i>1 && aClusters(i)==iClusterUnited && aClusters(i-1)==aClusters(i))
            aE_byClusters(i)=0;
        end;
        %Для первой клетки очередного кластера записать первое значение
        if(i>1 && aClusters(i)==iClusterUnited && aClusters(i-1)~=aClusters(i))
            aE_byClusters(i)=aE_byColumn(i);
        end;
    end;
    
    %2.19) сосчитать Etotal, просуммировав клетки массива 
%     iEtotal=0;
%     for i=1:1:ikIntensitiesLength
%         iEtotal=iEtotal+aE_byClusters(i);
%     end;
    %2.20) контроль Etotal: сумма по первым клеткам кластеров
    iEtotal=0;
    for i=1:1:ikIntensitiesLength
        %Первую клетку первого кластера в массиве сохраняем
        if( (i==1 && aClusters(i)==iClusterUnited) || (i==1 && ikIntensitiesLength>1 && aClusters(i)==aClusters(i+1)))
            iEtotal=iEtotal+aE_byClusters(i); % можно aE_byColumn(i)
        end;
        if(ikIntensitiesLength==1)
            msgbox('2.20) Error: ikIntensitiesLength==1. Image consists of one intensity or one cluster. EXITING program.');
            return;
        end;
        %Первую клетку очередного кластера суммируем
        if(i>1 && aClusters(i-1)~=aClusters(i))
            iEtotal=iEtotal+aE_byClusters(i);% можно aE_byColumn(i)
        end;
    end;
    %ПРОВЕРКА:
    if (iEtotal<iEtotalPreviousPartition)
        msgbox('2.20) Error: iEtotal<iEtotalPreviousPartition. Approximation error of current partition is less than approximation error of previous partition. EXITING program.');
        return;
    end;
    
    % 2.21)Вычислить и сохранить в массиве качество разбиения
    % Сигма сохраняется для вывода графика на экран
    %-- вычисляем сигму 
    iSigma=sqrt(iEtotal/numOfRows/numOfCols); % расчет iSigma
    %-- сохраняем сигму в массиве по соответсвующему индексу начиная с правого края.
    aSigmaValues(k-1)=iSigma; 
    %-- записываем порядковый номер разбиения для сигма
    aSigmaIndex(iIntensitiesNumOfNonEmpty-k+1)=iIntensitiesNumOfNonEmpty-k;
    %-- запоминание значения iEtotal текущего разбиения в массив aEValue
    aEValue(k-1)=iEtotal;
    %-- записываем порядковый номер разбиения для сум.кв.ош.
    aEIndex(iIntensitiesNumOfNonEmpty-k+1)=iIntensitiesNumOfNonEmpty-k;
    %-- запомнить значение Е (сум.кв.ош.) как прошлое для сравнения с новым будущим значением 
    iEtotalPreviousPartition=iEtotal;
    
    %РАСКОММЕНТИРОВАТЬ разделы 2.22, 2.23 при работе с изображениями
    %2.22) Сформировать разбиение
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
    
    %2.23) Сохранение текущего разбиения в память
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

%%РАСКОММЕНТИРОВАТЬ раздел 3 при работе с изображениями
%3] Завершение программы
% 3.1) Сохранение графка сигма для серии разбиений
% -- вывод и сохранение линейного графика сигма для серии разбиений
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
% -- вывод и сохранение логарфимического графика сигма для серии разбиений
% -- -- замена нуля на приближенное значение, чтобы обойти погоню в
% бесконечность
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

