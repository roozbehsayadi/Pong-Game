 # Pong game 
 I wrote a simple one-player Pong game with 8086 assembly. This is a mini-project for *Microprocessor and Assembly Language* course in *Shahid Beheshti Univeristy*. Hope you enjoy it!
 ## Executing the program
 I used [emu8086](https://download.cnet.com/Emu8086-Microprocessor-Emulator/3000-2069_4-10392690.html) to write and test my code. Open *pong.asm* file in this program, and click *compile* to create a *.com* file.
 
 You'll need [Dosbox](https://www.dosbox.com/download.php?main=1) to execute this file.
 
 After installing, open it. Type ```mount C C:\path\to\your\file.asm``` to switch to your folder. Now you can run the program by running these commands:
* ```C:```
* ```pong.com```
 ## How to Play
 Use *w* and *s* to move the racket. You'll lose if the ball touches the right border of the environment. Your goal is to reach 30 points.
## Additional Options
+ Whenever the ball touches the racket, its color changes randomly. 
+ Your score is shown at the top of game environment. 
+ Score is also shown in LED display, but you don't see it in Dosbox. 
