/* Copyright CelerSMS - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Author: Victor Celer <admin@celersms.com>
 * Last Update: September 2020
 */
package com.celer;

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.io.RandomAccessFile;

/** The COM class can be used to open and close a COM port, retrieve an input and output streams to perform I/O.
  * <p><a href="https://www.celersms.com/"><img style="position:absolute;top:-32px;right:16px" src="doc-files/logo.png" alt="CelerSMS"></a>
  * <p>This class will try to use the native driver, if available. Otherwise it will fallback to the Java RAF driver.
  */
public class COM{

   private RandomAccessFile raf;
   final COMInputStream is;
   final COMOutputStream os;

   protected COM(){
      os = new COMOutputStream(this);
      is = new COMInputStream(this);
   }

   protected COM(String comdev) throws IOException{
      this();
      raf = new RandomAccessFile(comdev, "rw");
   }

   /** Open the COM port.
     * @param comdev specifies the name of the COM port.
     * <p>In Windows the COM port names must start with "\\.\" if the port number is greater than 9, for example:
     * <pre>COM9
     *\\.\COM15</pre>
     * <b>Note:</b> Don't forget to escape the backslash character in Java!
     * <p>In Linux a typical COM port name can be:
     * <pre>/dev/ttyUSB1</pre>
     * @return The COM port instance, which can be used to read, write or close the port.
     * @throws IllegalArgumentException if the COM port name is null or empty.
     * @throws IOException if the port can't be opened. This can happen if the device is not connected.
     */
   public static final COM open(String comdev) throws IOException{
      if(comdev == null || comdev.length() == 0)
         throw new IllegalArgumentException("COM port not specified");
      String str;
      COM dev = null;
      try{
         dev = new N(comdev); // Switch to the native driver for Windows / Linux
      }catch(IllegalStateException ex){ /* NOOP: fallback to the RAF implementation */
      }catch(UnsatisfiedLinkError ex){  /* NOOP: fallback to the RAF implementation */
         System.err.println(ex);
      }
      if(dev == null)
         dev = new COM(comdev); // Default to RAF for any other OS or arch
      return dev;
   }

   /** Get an input stream, which can be used to read from this COM port.
     * @return The input stream. This stream is released implicitly when the COM port is closed by calling the {@link close()} method.
     */
   public final COMInputStream getInputStream(){ return is; }

   /** Get an output stream, which can be used to write to this COM port.
     * @return The output stream. This stream is released implicitly when the COM port is closed by calling the {@link close()} method.
     */
   public final COMOutputStream getOutputStream(){ return os; }

   /** Close the COM port.
     * Call this method to free the resources and streams. After closing the COM port any read or write operation will fail. It is
     * recommended to close the COM port when it is no longer needed.
     */
   public void close(){
      if(raf != null)
         try{
            raf.close();
         }catch(Exception ex){ /* NOOP */ }
      raf = null;
   }

   /** Test if the COM driver is native or Java (RAF).
     * @return If the driver is native returns {@code true}. Otherwise returns {@code false}.
     */
   public boolean isNative(){ return false; }

   protected void write(int bb) throws IOException{ raf.write(bb); }

   protected void write(byte[] buf) throws IOException{ raf.write(buf); }

   protected void write(byte[] buf, int off, int len) throws IOException{ raf.write(buf, off, len); }

   protected int read(){
      try{
         return raf.read();
      }catch(IOException ex){
         return -1;
      }
   }

   protected int read(byte[] buf){
      try{
         return raf.read(buf);
      }catch(IOException ex){
         return -1;
      }
   }

   protected int read(byte[] buf, int off, int len){
      try{
         return raf.read(buf, off, len);
      }catch(IOException ex){
         return -1;
      }
   }

   protected int skip(int nn){
      try{
         return raf.skipBytes(nn);
      }catch(IOException ex){
         return 0;
      }
   }
}
