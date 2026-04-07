/* Copyright CelerSMS - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Author: Victor Celer <admin@celersms.com>
 * Last Update: September 2020
 */
package com.celer;

import java.io.InputStream;

/** The COM input stream can be used to read from a COM port.
  * <p><a href="https://www.celersms.com/"><img style="position:absolute;top:-32px;right:16px" src="doc-files/logo.png" alt="CelerSMS"></a>
  * <p>The COM input stream follows the standard Java InputStream behavior, except for the following key difference:
  * <p>When using the native driver and reading into a byte buffer (refer to {@link read(byte[])} and {@link read(byte[], int, int)})
  * the call will only block for a maximum of 200ms if no data is available. This is useful to avoid blocking indefinitely if the
  * communication device stops responding. If not a single byte of input data is available after the 200ms timeout {@code -1} is returned
  * instead of {@code 0}. This was done to avoid the "underlying input stream returned zero bytes" exception when wrapping the COM
  * input stream into a Java buffered reader. When calling the single byte {@link read()} or the {@link skip(long)} method the operation
  * will block as specified in the standard Java InputStream API.
  * <p>On the other hand, when using the Java RAF driver all I/O operations will block indefinitely, as specified in the standard Java InputStream API.
  */
public class COMInputStream extends InputStream{

   private final COM pp;

   COMInputStream(COM port){ pp = port; }

   /** Reads the next byte of data from the COM port. The value byte is returned as an {@code int} in the range {@code 0} to {@code 255}.
     * If an I/O error is detected, like a device disconnection, the value {@code -1} is returned.
     * This method blocks until input data is available or an error is detected.
     * @return The next byte of data, or {@code -1} if no data.
     */
   @Override
   public final int read(){ return pp.read(); }

   /** Reads some number of bytes from the COM port and stores them into the buffer array {@code buf}. The number of bytes actually read is
     * returned as an integer. This method blocks until input data is available or an error is detected. When using the native driver
     * this method will block for 200ms at most.
     * <p>This method attempts to read at least one byte. If an error is detected the value {@code -1} is returned.
     * Otherwise, at least one byte is read and stored into {@code buf}.
     * <p>The first byte read is stored into element {@code buf[0]}, the next one into {@code buf[1]}, and so on. The number of bytes read
     * is, at most, equal to the length of {@code buf}.
     * <p>The {@code read(buf)} method has the same effect as {@code read(buf, 0, buf.length)}
     * @param buf The buffer into which the data is read.
     * @return The total number of bytes read into the buffer, or {@code -1} if an error was detected. The native driver will also
     * return {@code -1} if no data is available after the 200ms timeout.
     * @throws NullPointerException if {@code buf} is {@code null}
     */
   @Override
   public final int read(byte[] buf){ return pp.read(buf); }

   /** Reads up to {@code len} bytes from the COM port and stores them into the buffer array {@code buf}. The number of bytes actually read is
     * returned as an integer. This method blocks until input data is available or an error is detected. When using the native driver
     * this method will block for 200ms at most.
     * <p>This method attempts to read at least one byte. If an error is detected the value {@code -1} is returned.
     * Otherwise, at least one byte is read and stored into {@code buf}.
     * <p>The first byte read is stored into element {@code buf[0]}, the next one into {@code buf[1]}, and so on. The number of bytes read
     * is, at most, equal to {@code len}.
     * @param buf The buffer into which the data is read.
     * @param off The start offset in array {@code buf} at which the data is written.
     * @param len The maximum number of bytes to read.
     * @return The total number of bytes read into the buffer, or {@code -1} if an error was detected. The native driver will also
     * return {@code -1} if no data is available after the 200ms timeout.
     * @throws NullPointerException if {@code buf} is {@code null}
     * @throws IndexOutOfBoundsException if {@code off} is negative, {@code len} is negative, or {@code len} is greater than {@code buf.length - off}
     */
   @Override
   public final int read(byte[] buf, int off, int len){ return pp.read(buf, off, len); }

   /** Skips over and discards {@code nn} bytes of data from the COM port.
     * The {@code skip} method may end up skipping over some smaller number of bytes, possibly {@code 0}.
     * This may result due to an I/O error before {@code nn} bytes have been skipped. The actual number of bytes skipped is returned.
     * If {@code nn} is negative, no bytes are skipped.
     * @param nn The number of bytes to be skipped.
     * @return The actual number of bytes skipped. Can be {@code 0}.
     */
   @Override
   public final long skip(long nn){ return pp.skip((int)nn); }
}
