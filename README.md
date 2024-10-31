# ModifOfArifinClusteringMethod
Repository contains files of modifications of agglomerative multithreshold pixel clustering method of A.Z.Arifin and A.Asosno.

The methodArifinMod24.m file contains the Matlab code of the modified A.Z. Arifin and A. Asosno method of agglomerative multilevel thresholding of grayscale images. The modification consists in follows. Firstly, the distance between pairs of adjacent clusters is calculated using the formula for the increment of the total squared error. Secondly, the quality of each partition into clusters is assessed. 

The program receives an image at the input and checks whether it is 8-bit or 24-bit. In any case, it converts it to grayscale. 

During the execution of the main loop, the values are calculated and the partitions are generated. 

At the end, a graph of the approximation error values is displayed in linear and logarithmic scales. 

The program main loop is linear. One partition is generated per iteration. Working with large images, there is a slowdown due to the fact that the standard data output function in the Matlab environment takes a significant amount of time (it seems that it is not linear). It should be recoded if possible.

A way out of this situation is to output only a set of individual partitions, for example, from 15 to 1 cluster. Practice shows that the human visual perception experiences difficulties in distinguishing more than 15 different clusters (shades of gray) in one partition. 

10/31/2024 			Khanykov I.G.

