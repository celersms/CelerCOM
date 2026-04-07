/* Copyright CelerSMS - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Author: Victor Celer <admin@celersms.com>
 * Last Update: September 2020
 */
package com.celer;

import java.io.IOException;
import java.io.OutputStream;

/** The COM output stream can be used to write to a COM port.
  * <p><a href="https://www.celersms.com/"><img style="position:absolute;top:-32px;right:16px" src="doc-files/logo.png" alt="CelerSMS"></a>
  */
public class COMOutputStream extends OutputStream{

   private final COM pp;

   COMOutputStream(COM port){ pp = port; }

   /** Writes the specified byte to the COM port. The general contract for {@code write} is that one byte is written to the COM port.
     * The byte to be written is the eight low-order bits of the argument {@code bb}. The 24 high-order bits of {@code bb} are ignored.
     * @param bb The {@code byte}.
     * @throws IOException if an I/O error occurs. In particular, a device disconnection can trigger this error.
     */
   @Override
   public final void write(int bb) throws IOException{ pp.write(bb); }

   /** Writes {@code buf.length} bytes from the specified byte array to the COM port.
     * The general contract for {@code write(buf)} is that it should have exactly the same effect as the call {@code write(buf, 0, buf.length)}.
     * @param buf The byte array containing the data to be written.
     * @throws IOException if an I/O error occurs. In particular, a device disconnection can trigger this error.
     */
   @Override
   public final void write(byte[] buf) throws IOException{ pp.write(buf); }

   /** Writes {@code len} bytes from the specified byte array starting at offset {@code off} to the COM port.
     * The general contract for {@code write(buf, off, len)} is that some of the bytes in the array {@code buf} are written to the
     * COM port in order. Element {@code buf[off]} is the first byte written and {@code buf[off + len - 1]} is the last byte written.
     * @param buf The byte array containing the data to be written.
     * @param off The start offset in the data.
     * @param len The number of bytes to write.
     * @throws IOException if an I/O error occurs. In particular, a device disconnection can trigger this error.
     * @throws NullPointerException if {@code buf} is {@code null}
     * @throws IndexOutOfBoundsException if {@code off} is negative, {@code len} is negative, or {@code len} is greater than {@code buf.length - off}
     */
   @Override
   public final void write(byte[] buf, int off, int len) throws IOException{ pp.write(buf, off, len); }
}
