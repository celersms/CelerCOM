/* Copyright CelerSMS, 2018-2020
 * https://www.celersms.com
 *
 * Permission is hereby granted, free of charge, to any person obtaining
 * a copy of this software and associated documentation files (the
 * "Software"), to deal in the Software without restriction, including
 * without limitation the rights to use, copy, modify, merge, publish,
 * distribute, sublicense, and/or sell copies of the Software, and to
 * permit persons to whom the Software is furnished to do so, subject to
 * the following conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
 * LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
 * OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
 * WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

import com.celer.COM;
import java.io.*;

/* A simple TTY terminal on top of the CelerCOM library using Java I/O
 * streams. It can be used to exchange text commands, ex: AT commands.
 */
public final class TTY extends Thread{

   private static COM com;    // the COM port
   private static boolean sh; // a flag to stop the reading thread

   private TTY(){ /* Avoid direct instantiation */ }

   // Expect the COM port name as the command line parameter
   public static final void main(String[] args){
   
      String line, sCOM = null;
      if(args.length > 0){
         sCOM = args[0];
      }
      if(sCOM == null || sCOM.length() < 3){
         System.err.println("Please, specify the COM port");

      }else{
         try{

            // Try to open the COM port
            com = COM.open(sCOM);
            StringBuilder sb = new StringBuilder("Port ").append(sCOM).append(" opened");

            // Whether the driver is native or not is just informative in this example
            if(com.isNative()){
               sb.append(" (native driver)");
            }
            System.out.println(sb.toString());

            // Wrap the console into a buffered reader
            BufferedReader in = new BufferedReader(new InputStreamReader(System.in));

            // Wrap the COM port output stream into a print stream to handle text output
            PrintStream out = new PrintStream(com.getOutputStream(), true);

            // Launch a separate thread to read the responses from the COM port
            new TTY().start();

            // Read from the console and write to the COM port line by line
            while((line = in.readLine()) != null){
               out.println(line);
            }

         }catch(Throwable th){
            System.err.println(th);
         }finally{
            sh = true; // signal the thread to stop reading
            if(com != null){
               com.close();
            }
         }
      }
   }

   // Reading from the COM port in a separate thread
   @Override
   public final void run(){
      String line;

      // Wrap the COM port input stream into a buffered reader to read line by line
      BufferedReader in = new BufferedReader(new InputStreamReader(com.getInputStream()));

      // Keep reading while the main thread is active
      while(!sh){
         line = null;
         try{

            // Read the next line of text from the COM port
            line = in.readLine();
         }catch(Exception ex){ /* Ignore any errors in this example to keep it simple */ }

         // The text read from the COM port is flushed to the console
         if(line != null && line.length() > 0){
            System.out.println(line);
         }
      }
   }
}
