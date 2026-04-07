/* Copyright CelerSMS - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Author: Victor Celer <admin@celersms.com>
 * Last Update: December 2020
 */
package com.celer;

import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.io.FileOutputStream;

// Native driver
final class N extends COM{

   private int hFile = -1;
   private static boolean drvld;

   protected N(String comdev) throws IllegalStateException, IOException{
      if(!drvld){
         int xx = 0;
         String str;
         if((str = System.getProperty("os.name")) != null && str.length() > 2)
            xx = str.charAt(0) << 24 | str.charAt(1) << 16 | str.charAt(2) << 8 | 0x20202000; // to lowercase
         if((str = System.getProperty("os.arch")) != null){
            if(str.endsWith("d64") || str.endsWith("_64"))
               xx |= 1;
            else if(str.endsWith("86"))
               xx |= 2;
            else if(str.startsWith("arm64") || str.startsWith("aarch64"))
               xx |= 3;
            else if(str.startsWith("arm") || str.startsWith("aarch32"))
               xx |= 4;
         }
         str = null;
         switch(xx){
         case 0x77696E01: // Windows x86-64
            str = "celer64.dll";
            break;
         case 0x77696E02: // Windows x86
            str = "celer32.dll";
            break;
//         case 0x77696E03: // Windows ARM64
//            str = "aarch64.dll";
//            break;
//         case 0x77696E04: // Windows ARM32
//            str = "aarch32.dll";
//            break;
         case 0x6C696E01: // Linux x86-64
            str = "libceler64.so";
            break;
         case 0x6C696E02: // Linux x86
            str = "libceler32.so";
            break;
//         case 0x6C696E03: // Linux ARM64
//            str = "libaarch64.so";
//            break;
         case 0x6C696E04: // Linux ARM32
            str = "libaarch32.so";
         }
         if(str == null)
            throw new IllegalStateException(); // os.name + os.arch combination not supported
         File ftmp = null;
         String tmp = System.getProperty("java.io.tmpdir");
         if(tmp != null){
            ftmp = new File(tmp);
            if(!ftmp.canWrite())
               ftmp = null;
         }
         ftmp = new File(ftmp, str);
         if(!ftmp.exists()){
            InputStream is = null;
            OutputStream os = null;
            try{
               if((is = N.class.getResourceAsStream(new StringBuilder("/jni/").append(str).toString())) != null){
                  byte[] buf = new byte[2048];
                  os = new FileOutputStream(ftmp);
                  while((xx = is.read(buf, 0, 2048)) != -1)
                     os.write(buf, 0, xx);
               }
            }catch(Exception ex){
               System.err.println(ex);
            }finally{
               if(os != null)
                  try{
                     os.close();
                  }catch(Exception ex){ /* NOOP */ }
               if(is != null)
                  try{
                     is.close();
                  }catch(Exception ex){ /* NOOP */ }
            }
         }
         System.load(ftmp.getAbsolutePath());
         drvld = true;
      }
      if((hFile = o(comdev)) == -1)
         throw new IOException("Device unavailable");
   }

   // Native stubs
   private native final void c(int hh);                             // close
   private native final int o(String comdev);                       // open
   private native final int r(int hh, byte[] bb, int off, int len); // read
   private native final int w(int hh, byte[] bb, int off, int len); // write

   @Override
   protected final void write(int bb) throws IOException{
      if(w(hFile, new byte[]{ (byte)bb }, 0, 1) <= 0)
         throw new IOException("write error");
   }

   @Override
   protected final void write(byte[] bb) throws IOException{
      if(bb == null)
         throw new NullPointerException();
      int jj, ii = 0, len = bb.length;
      while(ii < len){
         if((jj = w(hFile, bb, ii, len - ii)) <= 0)
            throw new IOException("write error");
         ii += jj;
      }
   }

   @Override
   protected final void write(byte[] bb, int off, int len) throws IOException{
      if(bb == null)
         throw new NullPointerException();
      int ii = 0, jj = bb.length;
      if((off < 0) || (off > jj) || (len < 0) || (off + len > jj))
         throw new IndexOutOfBoundsException();
      while(ii < len){
         if((jj = w(hFile, bb, off + ii, len - ii)) <= 0)
            throw new IOException("write error");
         ii += jj;
      }
   }

   @Override
   protected final int read(){
      byte[] lbuf = new byte[1];
      while(true)
         switch(r(hFile, lbuf, 0, 1)){
         case -1: // EOF (i.e. device disconnected)
            return -1;
         case 0: // no data, wait and retry
            try{
               Thread.sleep(200);
            }catch(InterruptedException ex){ /* NOOP */ }
            continue;
         default:
            return lbuf[0] & 0xFF;
         }
   }

   @Override
   protected final int read(byte[] bb){
      if(bb == null)
         throw new NullPointerException();
      int ii;
      if((ii = r(hFile, bb, 0, bb.length)) <= 0)
         ii = -1; // W/A for "underlying input stream returned zero bytes"
      return ii;
   }

   @Override
   protected final int read(byte[] bb, int off, int len){
      if(bb == null)
         throw new NullPointerException();
      if(off < 0 || len < 0 || len > bb.length - off)
         throw new IndexOutOfBoundsException();
      int ii;
      if((ii = r(hFile, bb, off, len)) <= 0)
         ii = -1; // W/A for "underlying input stream returned zero bytes"
      return ii;
   }

   @Override
   protected final int skip(int nn){
      if(nn <= 0)
         return 0;
      int nr, rem = nn, size = (int)Math.min(1024, rem);
      byte[] lbuf = new byte[size];
      while(rem > 0 && (nr = r(hFile, lbuf, 0, (int)Math.min(size, rem))) >= 0)
         rem -= nr;
      return nn - rem;
   }

   @Override
   public final void close(){
      if(hFile != -1)
         c(hFile);
      hFile = -1; // mark as closed
   }

   @Override
   public final boolean isNative(){ return true; }
}
