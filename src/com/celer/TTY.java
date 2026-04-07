/* Copyright CelerSMS - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Author: Victor Celer <admin@celersms.com>
 * Last Update: September 2020
 */
package com.celer;

//import com.celer.COM;
import java.io.InputStream;
import java.io.OutputStream;
import java.io.InputStreamReader;
import java.io.BufferedReader;
import java.io.PrintStream;

public final class TTY extends Thread{

   private static COM com;
   private static boolean sh;

   private TTY(){ /* NOOP */ }

   public static final void main(String[] args){
      String line, sCOM = null;
      if(args.length > 0)
         sCOM = args[0];
      if(sCOM == null || sCOM.length() < 3)
         System.err.println("Please, specify the COM port");
      else
         try{
            com = COM.open(sCOM);
            StringBuilder sb = new StringBuilder("Port ").append(sCOM).append(" opened");
            if(com.isNative())
               sb.append(" (native driver)");
            System.out.println(sb.toString());
            BufferedReader in = new BufferedReader(new InputStreamReader(System.in));
            PrintStream out = new PrintStream(com.getOutputStream(), true);
            new TTY().start();
            while((line = in.readLine()) != null)
               out.println(line);
         }catch(Throwable th){
            System.err.println(th);
         }finally{
            sh = true;
            if(com != null)
               com.close();
         }
   }

   @Override
   public final void run(){
      String line;
      BufferedReader in = new BufferedReader(new InputStreamReader(com.getInputStream()));
      while(!sh){
         line = null;
         try{
            line = in.readLine();
         }catch(Exception ex){ /* NOOP */ }
         if(line != null && line.length() > 0)
            System.out.println(line);
      }
   }
}
