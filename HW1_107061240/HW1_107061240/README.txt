107061240 蔡忠浩

Part2:
在rop3_smart.v的部分上，我把hw1 pdf上的公式輸入上去即完成這個部分。
在testbench的部份上，我拿part1的一些結果來做修改。我把part1有關讀取golden.dat的部分全部拿掉，因為結果可以使用助教給的公式算出來(rop3_smart.v)。
我把HW1上面所有的MODE宣告為一個二微陣列。宣告完後，我用四個for loop去完成所有需要執行的部分，第一圈選MODE，第二圈選P，第三圈選S，第四圈選D。
在做完所有宣告之後，去比較rop3_smart.v跟rop3_lut16.v的結果一不一樣，一樣的話這個部分就完成了。

Part3:
在rop3_lut256.v部份上跟rop3_lut16.v極為類似，只是從原本只有15個mode要選，到我們需要自己找到其他的mode讓我們能執行256種不同的運算，就可以完成rop3_lut256.v。
在testbench的部分上，他會跟part2的很像，只是換成rop3_lut256.v的結果會跟rop3_smart.v的結果做比較，所以我就把原本只選15個mode，換成他能選擇256個mode，就可以完
成這個部分，然後為了觀察方便，我讓程式印出跑到第幾個mode，如果mode能成功跑到8'hff，那這個部分即算完成。

Part4:
在task的部份上，我依著助教的指示，把原本在testbench(test_rop3_lut256.v)上的一些程式碼移到task檔裡面，然後把移到task檔裡面的程式碼從原本的testbench中刪除。
然後再task檔面面更改mode的上下界，下界為MODE_L，上界為MODE_U，然後記得在這題的testbench(test_rop3)上定義上下界的參數，然後這個部分即可完成。
以下為老師所要求的函式:
$ ncverilog test_rop3.v rop3_lut256.v rop3_smart.v +define+MODE_L=0+MODE_U=63

$ ncverilog test_rop3.v rop3_lut256.v rop3_smart.v +define+MODE_L=64+MODE_U=127

$ ncverilog test_rop3.v rop3_lut256.v rop3_smart.v +define+MODE_L=128+MODE_U=255


How you find out all the 256 functions.

首先我觀察到mode會跟boolean equation出來的數值會是一樣的，然後在同學的提示下，了解到8'hab會是8'ha0跟8'h0b經過or gate出來的結果。
(例如想要8'h56，就可以將8'h50 跟8'h06用or gate就能得到我們想要的結果)
所以只要把所有的8'hf0~8'h00，跟所有的從8'h00~8'h0f找出來，我們就能得到所有256種結果，於是我就從老師給的table找到一些規律性，把我上面所說需要找的東西全部找到，
最後把256種結果打出來。



