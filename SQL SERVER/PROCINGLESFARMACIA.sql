use PHARMACYSYSTEM0DB;
Go

/*
C�DIGOS DE ERROR 
C�D: 50005 -- REGISTRO DUPLICADO: Este error se genera cuando un usuario intenta insertar un registro que ya existe en la base de datos
              violando una regla de unicidad.Por ejemplo, intentar registrar un producto que ya esta registrado. 
C�D: 50006   --REGISTRO CON DEPENDENCIAS: Este error se activa cuando se intenta eliminar un registro que est� vinculado a otros datos importantes
              Por ejemplo, no se puede borrar un usuario porque ya tiene ventas asociadas; eliminarlo crear�a una inconsistencia en los reportes de ventas.
C�D: 50007 --STOCK INSUFICIENTE: Este error indica que la cantidad disponible en inventario es menor a la requerida para procesar una operaci�n, como una
              venta o una baja de productos. SQL Server detecta esta condici�n y bloquea la transacci�n para evitar inconsistencias o valores negativos 
              en el stock.
C�D: 50008 -- OPERACI�N EXITOSA: La opereci�n se complet� correctamente sin errores. Se confirma que el proceso fue exitoso y no se requieren acciones 
              adicionales.
C�D: 50009 -- SIN RESULTADOS: Este error indica que no se han encontrado datos que cumplan con los criterios de b�squeda especificados. Indica que la
              consulta se ejecut� correctamente pero no retorn� ning�n registro.
C�D: 50010 -- ERROR EN LA ATUALIZACI�N DE DATOS: Este error indica que ocurri� un fallo inesperado durante el proceso de actualizaci�n en la base de 
              datos, impidiendo que los cambios se aplicaran correctamente. puede deberse a problemas de integridad referencial, conflictos de
              concurrencia, de conexi�n. El sistema debe manejar este error para preservar la consistencia de los datos y notificar a usuario 
              o sistema correspondiente.
C�D: 50011 -- LA COMPRA DEBE TENER ALMENOS 1 PRODUCTO: [definir]

C�D: 50012 -- NO SE PUDE REGISTRAR UN PRODUCTO VENCIDO: [definir]


*/

--PROCEDIMIENTO ALMACENADO PARA REGISTAR UN USUARIO
CREATE PROC USP_REGISTERUSERS(
    @Name VARCHAR (65),
    @LastName VARCHAR (65),
    @Password VARCHAR(250),
    @Mail VARCHAR(100),
    @Phone VARCHAR(30),
    @IsActive BIT,
    @RolId INT
)
AS
BEGIN
    SET NOCOUNT ON; -- Evita mensajes de recuento de filas afectadas.

    -- Se inicia un bloque TRY para capturar posibles errores.
    BEGIN TRY
        -- Comprueba si el usuario ya existe.
        IF NOT EXISTS( SELECT 1 FROM Users WHERE UserName = @Name AND UserLastName = @LastName)
        BEGIN
            -- Si no existe, inserta el nuevo usuario.
            INSERT INTO Users(UserName, UserLastName ,UserPassword,mail,UserPhone,RegisteredDate,Isactive,RolId)
            VALUES (@Name,@LastName,@Password,@Mail,@Phone, GETDATE(), @IsActive,@RolId);

            -- Opcional: Devuelve el ID del usuario reci�n creado.
            SELECT SCOPE_IDENTITY() AS NewUserId;
        END
        ELSE
        BEGIN
            -- Si el usuario ya existe, lanza un error personalizado.
            -- Formato: THROW [c�digo_error], [mensaje], [estado]
            ;THROW 50005, 'Error de registro: El usuario ya existe y no puede ser duplicado.', 1;
        END
    END TRY
    -- Se inicia un bloque CATCH para manejar cualquier error que ocurra en el bloque TRY.
    BEGIN CATCH
        -- Vuelve a lanzar el error original para que la aplicaci�n cliente lo reciba.
        THROW;
    END CATCH

    SET NOCOUNT OFF;
END
GO

-- editar usuarios 
CREATE  PROC USP_EDITUSERS(
    @UserId INT,
    @Name VARCHAR (65),
    @LastName VARCHAR (65),
    @Password VARCHAR(250),
    @Mail VARCHAR(100),
    @Phone VARCHAR(30),
    @IsActive BIT,
    @RolId INT
)
AS
BEGIN
    SET NOCOUNT ON; -- Evita mensajes de recuento de filas afectadas.

    -- Se inicia un bloque TRY para capturar posibles errores.
    BEGIN TRY
        -- Comprueba si ya existe otro usuario con el mismo nombre (excluyendo al usuario actual).
        IF NOT EXISTS (SELECT 1 FROM Users WHERE UserName = @Name AND UserId != @UserId)
        BEGIN
            -- Si el nombre es �nico, procede a actualizar los datos del usuario.
            UPDATE Users SET
                UserName = @Name,
                UserLastName = @LastName,
                UserPassword = @Password,
                Mail = @Mail,
                UserPhone = @Phone,
                IsActive = @IsActive,
                RolId = @RolId
            WHERE UserId = @UserId;

            -- Si la actualizaci�n no afect� a ninguna fila (porque el UserId no existe), se lanza un error.
            IF @@ROWCOUNT = 0
            BEGIN
                ;THROW 50004, 'Error de edici�n: El usuario con el ID especificado no fue encontrado.', 1;
            END
        END
        ELSE
        BEGIN
            -- Si ya existe otro usuario con ese nombre, lanza un error personalizado.
            -- Formato: THROW [c�digo_error], [mensaje], [estado]
            ;THROW 50005, 'Error de edici�n: El nombre de usuario ya est� en uso por otra cuenta.', 1;
        END
    END TRY
    -- Se inicia un bloque CATCH para manejar cualquier error que ocurra en el bloque TRY.
    BEGIN CATCH
        -- Vuelve a lanzar el error original para que la aplicaci�n cliente lo reciba.
        THROW;
    END CATCH

    SET NOCOUNT OFF;
END
GO



--PROCEDIMIENTO PARA ELIMINAR USUARIOS

CREATE PROC USP_DELETEUSERS(
@UserId INT,
@Message VARCHAR(500) OUTPUT,
@Result INT OUTPUT
)
AS 
BEGIN
SET NOCOUNT ON -- SET NOCOUNT ON ES EVITAR QUE SQL SERVER ENVIE UN MENSAJE DE VUELTA AL CLIENTE INDICANDO EL N�MERO DE FILAS AFECTADAS POR CADA INSTRUCCI�N 
SET @Message = ''
SET @Result = 0
DECLARE @passed BIT = 1

IF EXISTS (SELECT * FROM Purchases P
            INNER JOIN Users U ON U.UserId = P.UserId -- PRIMERO VERIFICA SI EL USUARIO NO HA REALIZADO UNA COMPRA
			WHERE P.UserId = @UserId
			)
			BEGIN
			SET @passed = 0
			SET @Result = 0
            SET @Message = @Message + 'ERROR EN LA SOLICITUD C�D: 50006' -- NO PUEDES ELIMINAR ESTE REGISTRO PORQUE ESTA SIENDO UTILIZADO EN OTRA PARTE
			END
IF EXISTS (SELECT * FROM InventoryLoss LI
            INNER JOIN Users U ON U.UserId = LI.UserId -- LUEGO VERIFICA SI EL USUARIO NO HA REALIZADO UNA BAJA
			WHERE LI.UserId = @UserId
			)
			BEGIN
			SET @passed = 0
			SET @Result = 0
            SET @Message = @Message + 'ERROR EN LA SOLICITUD C�D: 50006' -- NO PUEDES ELIMINAR ESTE REGISTRO PORQUE ESTA SIENDO UTILIZADO EN OTRA PARTE
			END
IF EXISTS (SELECT * FROM Invoices I
            INNER JOIN Users U ON U.UserId = I.UserId --LUEGO VERIFICA SI  EL USUARIO NO HA REALIZADO UNA FACTURA
			WHERE U.UserId = @UserId
			)
			BEGIN
			SET @passed = 0
			SET @Result = 0
SET @Message = @Message + 'ERROR EN LA SOLICITUD C�D: 50006'-- NO PUEDES ELIMINAR ESTE REGISTRO PORQUE ESTA SIENDO UTILIZADO EN OTRA PARTE
			END
			IF(@passed = 1) -- SI EL PASO SIGUE SIENDO 1 ES PORQUE SU VALOR NO CAMBIO, NO ENTR� A LOS CONDICIONALES Y PROSIGUE CON LA ELIMINACI�N
			BEGIN 
			DELETE FROM Users WHERE UserId = @UserId
			SET @Result = 1 -- EL resultado cambia a 1, osea todo sali� bien
			END
END
GO




--PROCEDIMIENTO ALMACENADO PARA REGISTAR UN PRODUCTO

CREATE OR ALTER PROC USP_REGISTERPRODUCTS(
    @ProductTradeName VARCHAR(150),
    @ProductGenericName VARCHAR(150),
    @CategoryId INT,
    @SalePrice DECIMAL(10,2),
    @PurchasePrice DECIMAL(10,2),
    @PresentationId INT,
    @ConcentrationId INT,
    @SupplierId INT,
    @BrandId INT,
    @CriticalStock INT,
    @Isactive BIT
)
AS
BEGIN
    SET NOCOUNT ON; -- Evita mensajes de recuento de filas afectadas.

    BEGIN TRY
        -- Comprueba si ya existe un producto con la misma combinaci�n de atributos �nicos.
        IF NOT EXISTS (
            SELECT 1
            FROM Products
            WHERE
                ProductTradeName = @ProductTradeName AND
                ProductGenericName = @ProductGenericName AND
                CategoryId = @CategoryId AND
                ConcentrationId = @ConcentrationId AND
                PresentationId = @PresentationId AND
                BrandId = @BrandId
        )
        BEGIN
            -- Si no existe, inserta el nuevo producto.
            INSERT INTO Products (
                ProductTradeName, ProductGenericName, CategoryId, SalePrice, PurchasePrice,
                PresentationId, ConcentrationId, SupplierId, BrandId, CriticalStock,
                RegisteredDate, Isactive
            )
            VALUES (
                @ProductTradeName, @ProductGenericName, @CategoryId, @SalePrice, @PurchasePrice,
                @PresentationId, @ConcentrationId, @SupplierId, @BrandId, @CriticalStock,
                GETDATE(), @Isactive
            );

            -- Devuelve el ID del producto reci�n creado como un conjunto de resultados.
            SELECT SCOPE_IDENTITY() AS NewProductId;
        END
        ELSE
        BEGIN
            -- Si el producto ya existe, lanza el error de registro duplicado.
            -- C�D: 50005
            ;THROW 50005, 'Error de registro: Ya existe un producto con el mismo nombre comercial, gen�rico, categor�a, concentraci�n, presentaci�n y marca.', 1;
        END

    END TRY
    BEGIN CATCH
        -- Vuelve a lanzar cualquier error capturado para que la aplicaci�n cliente lo reciba.
        THROW;
    END CATCH

    SET NOCOUNT OFF;
END
GO



-- PROCEDIMIENTO ALMACENADO PARA EDITAR LOS DATOS UN PRODUCTO
CREATE OR ALTER PROC USP_EDITPRODUCTS(
    @ProductId INT,
    @ProductTradeName VARCHAR(150),
    @ProductGenericName VARCHAR(150),
    @CategoryId INT,
    @SalePrice DECIMAL(10,2),
    @PurchasePrice DECIMAL(10,2),
    @PresentationId INT,
    @ConcentrationId INT,
    @SupplierId INT,
    @BrandId INT,
    @CriticalStock INT,
    @Isactive BIT
)
AS
BEGIN
    SET NOCOUNT ON; -- Evita mensajes de recuento de filas afectadas.

    BEGIN TRY
        -- Comprueba si el nuevo nombre comercial ya est� siendo utilizado por OTRO producto.
        IF NOT EXISTS (
            SELECT 1
            FROM Products
            WHERE
                ProductTradeName = @ProductTradeName AND
                ProductId != @ProductId
        )
        BEGIN
            -- Si el nombre es �nico (o es el mismo del producto actual), procede con la actualizaci�n.
            UPDATE Products SET
                ProductTradeName = @ProductTradeName,
                ProductGenericName = @ProductGenericName,
                CategoryId = @CategoryId,
                SalePrice = @SalePrice,
                PurchasePrice = @PurchasePrice,
                PresentationId = @PresentationId,
                ConcentrationId = @ConcentrationId,
                SupplierId = @SupplierId,
                BrandId = @BrandId,
                CriticalStock = @CriticalStock,
                Isactive = @Isactive
            WHERE ProductId = @ProductId;

            -- Verifica si la actualizaci�n afect� a alguna fila. Si no, el ProductId no exist�a.
            IF @@ROWCOUNT = 0
            BEGIN
                -- C�D: 50009 - Sin Resultados (el producto a editar no se encontr�).
                ;THROW 50009, 'Error de edici�n: No se encontr� ning�n producto con el ID especificado.', 1;
            END
        END
        ELSE
        BEGIN
            -- Si el nombre comercial ya est� en uso por otro producto, lanza el error de duplicado.
            -- C�D: 50005
            ;THROW 50005, 'Error de edici�n: El nombre comercial del producto ya est� en uso por otro producto.', 1;
        END

    END TRY
    BEGIN CATCH
        -- Vuelve a lanzar cualquier error capturado para que la aplicaci�n cliente lo reciba.
        THROW;
    END CATCH

    SET NOCOUNT OFF;
END
GO

--PROCEDIMIENTO PARA ELIMINAR PRODUCTOS

CREATE OR ALTER PROC USP_DELETEPRODUCTS(
    @ProductId INT
)
AS
BEGIN
    SET NOCOUNT ON; -- Evita mensajes de recuento de filas afectadas.

    BEGIN TRY
        -- Se consolida la verificaci�n de todas las dependencias en una sola consulta.
        -- Si el producto existe en CUALQUIERA de las tablas de detalle, se lanza un error.
        IF EXISTS (SELECT 1 FROM PurchasingDetail WHERE ProductId = @ProductId) OR
           EXISTS (SELECT 1 FROM SalesDetails WHERE ProductId = @ProductId) OR
           EXISTS (SELECT 1 FROM InventoryLoss WHERE ProductId = @ProductId)
        BEGIN
            -- Si se encuentra una dependencia, se lanza el error correspondiente y se detiene la ejecuci�n.
            -- C�D: 50006
            ;THROW 50006, 'No se puede eliminar el producto porque tiene registros asociados (detalles de compra, detalles de venta o bajas de inventario).', 1;
        END

        -- Si no hay dependencias, se procede con la eliminaci�n.
        DELETE FROM Products WHERE ProductId = @ProductId;

        -- Se verifica si la eliminaci�n afect� a alguna fila.
        -- Si @@ROWCOUNT es 0, significa que el ProductId no exist�a en la tabla Products.
        IF @@ROWCOUNT = 0
        BEGIN
            -- Se lanza un error indicando que el producto a eliminar no fue encontrado.
            -- C�D: 50009
            ;THROW 50009, 'Error de eliminaci�n: No se encontr� ning�n producto con el ID especificado.', 1;
        END

    END TRY
    BEGIN CATCH
        -- Vuelve a lanzar cualquier error capturado para que la aplicaci�n cliente lo reciba.
        THROW;
    END CATCH

    SET NOCOUNT OFF;
END
GO

--PROCEDIMIENTO ALMACENADO PARA AGREGAR MARCAS

CREATE OR ALTER PROC USP_REGISTERBRANDS(
    @BrandName NVARCHAR(100),
    @BrandDescription NVARCHAR(300),
    @IsActive BIT
)
AS
BEGIN
    SET NOCOUNT ON; -- Evita mensajes de recuento de filas afectadas.

    BEGIN TRY
        -- Comprueba si ya existe una marca con el mismo nombre y descripci�n.
        IF NOT EXISTS (SELECT 1 FROM Brands WHERE BrandName = @BrandName AND BrandDescription = @BrandDescription)
        BEGIN
            -- Si no existe, inserta la nueva marca.
            INSERT INTO Brands (BrandName, BrandDescription, Isactive, RegisteredDate)
            VALUES (@BrandName, @BrandDescription, @IsActive, GETDATE());

            -- Devuelve el ID de la marca reci�n creada como un conjunto de resultados.
            SELECT SCOPE_IDENTITY() AS NewBrandId;
        END
        ELSE
        BEGIN
            -- Si la marca ya existe, lanza el error de registro duplicado.
            -- C�D: 50005
            ;THROW 50005, 'Error de registro: Ya existe una marca con el mismo nombre y descripci�n.', 1;
        END

    END TRY
    BEGIN CATCH
        -- Vuelve a lanzar cualquier error capturado para que la aplicaci�n cliente lo reciba.
        THROW;
    END CATCH

    SET NOCOUNT OFF;
END
GO
--PROCEDIMIENTO PARA ACTUALIZAR UNA MARCA

CREATE OR ALTER PROC USP_EDITBRANDS(
    @BrandId INT,
    @BrandName NVARCHAR(100),
    @BrandDescription NVARCHAR(300),
    @IsActive BIT
)
AS
BEGIN
    SET NOCOUNT ON; -- Evita mensajes de recuento de filas afectadas.

    BEGIN TRY
        -- Comprueba si el nuevo nombre de la marca ya est� siendo utilizado por OTRA marca.
        IF NOT EXISTS (SELECT 1 FROM Brands WHERE BrandName = @BrandName AND BrandId != @BrandId)
        BEGIN
            -- Si el nombre es �nico, procede con la actualizaci�n.
            UPDATE Brands SET
                BrandName = @BrandName,
                BrandDescription = @BrandDescription,
                Isactive = @IsActive
            WHERE BrandId = @BrandId;

            -- Verifica si la actualizaci�n afect� a alguna fila. Si no, la BrandId no exist�a.
            IF @@ROWCOUNT = 0
            BEGIN
                -- C�D: 50009 - Sin Resultados (la marca a editar no se encontr�).
                ;THROW 50009, 'Error de edici�n: No se encontr� ninguna marca con el ID especificado.', 1;
            END
        END
        ELSE
        BEGIN
            -- Si el nombre de la marca ya est� en uso por otra, lanza el error de duplicado.
            -- C�D: 50005
            ;THROW 50005, 'Error de edici�n: El nombre de la marca ya est� en uso.', 1;
        END

    END TRY
    BEGIN CATCH
        -- Vuelve a lanzar cualquier error capturado para que la aplicaci�n cliente lo reciba.
        THROW;
    END CATCH

    SET NOCOUNT OFF;
END
GO

--PROCEDIMIENTO PARA ELIMINAR MARCA

CREATE OR ALTER PROC USP_DELETEBRANDS(
    @BrandId INT
)
AS
BEGIN
    SET NOCOUNT ON; -- Evita mensajes de recuento de filas afectadas.

    BEGIN TRY
        -- Comprueba si la marca est� vinculada a alg�n producto.
        IF EXISTS (SELECT 1 FROM Products WHERE BrandId = @BrandId)
        BEGIN
            -- Si existe una dependencia, lanza el error correspondiente y detiene la ejecuci�n.
            -- C�D: 50006
            ;THROW 50006, 'No se puede eliminar la marca porque est� asociada a uno o m�s productos.', 1;
        END

        -- Si no hay dependencias, procede con la eliminaci�n.
        DELETE FROM Brands WHERE BrandId = @BrandId;

        -- Verifica si la eliminaci�n afect� a alguna fila.
        -- Si @@ROWCOUNT es 0, significa que la BrandId no exist�a.
        IF @@ROWCOUNT = 0
        BEGIN
            -- Lanza un error indicando que la marca a eliminar no fue encontrada.
            -- C�D: 50009
            ;THROW 50009, 'Error de eliminaci�n: No se encontr� ninguna marca con el ID especificado.', 1;
        END

    END TRY
    BEGIN CATCH
        -- Vuelve a lanzar cualquier error capturado para que la aplicaci�n cliente lo reciba.
        THROW;
    END CATCH

    SET NOCOUNT OFF;
END
GO

----------------------------------------------------------------en proceso ------------------------------------------------------------------------------------
--PROCEDIMIENTO ALMACENADO PARA AGREGAR PROVEEDORES

CREATE PROC USP_REGISTERSUPPLIERS(
@SupplierName NVARCHAR(100),
@RNC NVARCHAR(300),
@Mail NVARCHAR(100),
@SupplierPhone NVARCHAR(30),
@SupplierAddress NVARCHAR(150),
@IsActive BIT, 
@Message VARCHAR(500) OUTPUT,
@Result INT OUTPUT
)
AS
BEGIN
SET NOCOUNT ON -- SET NOCOUNT ON ES EVITAR QUE SQL SERVER ENVIE UN MENSAJE DE VUELTA AL CLIENTE INDICANDO EL N�MERO DE FILAS AFECTADAS POR CADA INSTRUCCI�N 
SET @Message = ''
SET @Result = 0
  IF NOT EXISTS (SELECT * FROM Suppliers WHERE SupplierName = @SupplierName AND RNC = @RNC)
    BEGIN
  INSERT INTO  Suppliers(SupplierName, RNC,Mail,SupplierPhone,SupplierAddress, Isactive, RegisteredDate)VALUES
                     (@SupplierName, @RNC,@Mail,@SupplierPhone,@SupplierAddress, @IsActive, GETDATE())
     SET @Result = SCOPE_IDENTITY()

 END
  ELSE 
    SET @Message = 'ERROR EN EL REGISTRO C�D: 50005'
END
GO

--PROCEDIMIENTO PARA ACTUALIZAR PROVEEDORES

CREATE PROC USP_EDITSUPPLIERS(
@SupplierId INT,
@SupplierName NVARCHAR(100),
@RNC NVARCHAR(300),
@Mail NVARCHAR(100),
@SupplierPhone NVARCHAR(30),
@SupplierAddress NVARCHAR(150),
@IsActive BIT, 
@Message VARCHAR(500) OUTPUT,
@Result INT OUTPUT

)
AS
BEGIN 
SET NOCOUNT ON
SET @Message = ''
SET @Result = 0

IF NOT EXISTS (SELECT * FROM Suppliers WHERE SupplierName = @SupplierName AND SupplierId = @SupplierId)
BEGIN
UPDATE Suppliers  SET 
SupplierName =  @SupplierName,
RNC = @RNC,
Mail = @Mail,
SupplierPhone = @SupplierPhone,
SupplierAddress = @SupplierAddress,
IsActive = @IsActive
WHERE SupplierId  = @SupplierId 
SET @Result = 1
END
ELSE 
SET @Message = 'ERROR EN EL REGISTRO C�D: 50005'
END
GO

--PROCEDIMIENTO PARA ELIMINAR PROVEEDORES

CREATE PROC USP_DELETESUPPLIERS(
@SupplierId    INT,
@Message VARCHAR(500) OUTPUT,
@Result INT OUTPUT
)
AS
BEGIN
SET @Result = 0
SET @Message = ''
DECLARE @passed BIT = 1


IF EXISTS (SELECT * FROM Products P -- verifica si el proveedor no esta relacionado con un producto
            INNER JOIN Suppliers S ON S.SupplierId = P.SupplierId
			WHERE S.SupplierId = @SupplierId
			)
			BEGIN
			SET @passed = 0
			SET @Result = 0
            SET @Message = @Message + 'ERROR EN LA SOLICITUD C�D: 50006'
			END
IF EXISTS (SELECT * FROM Purchases P  -- verifica si el proveedor no esta registrado en una compra
            INNER JOIN Suppliers S ON S.SupplierId = P.SupplierId
			WHERE S.SupplierId = @SupplierId
			)
			BEGIN
			SET @passed = 0
			SET @Result = 0
            SET @Message = @Message + 'ERROR EN LA SOLICITUD C�D: 50006'
			END
IF EXISTS (SELECT * FROM SupplierBrand SB  -- verifica si el proveedor no esta relacionado con alguna marca
            INNER JOIN Suppliers S ON S.SupplierId = SB.SupplierId
			WHERE S.SupplierId = @SupplierId
			)
			BEGIN
			SET @passed = 0
			SET @Result = 0
            SET @Message = @Message + 'ERROR EN LA SOLICITUD C�D: 50006'
			END

			IF(@passed = 1)
			BEGIN 
			DELETE FROM Suppliers WHERE SupplierId = @SupplierId
			SET @Result = 1
			END
END 
GO




--PROCEDIMIENTO ALMACENADO PARA AGREGAR BAJAS EN EL INVENTARIO
CREATE PROC USP_REGISTERINVENTORYLOSS(
    @BatchId INT,
    @Quantity INT,
    @ProductId INT,
    @UserId INT,
    @Reason NVARCHAR(200),
    @Message VARCHAR(500) OUTPUT,
    @Result INT OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON
    SET @Message = ''
    SET @Result = 0

    -- Verificar que existe el lote y tiene suficiente cantidad
    IF EXISTS (SELECT 1 FROM ProductBatches 
               WHERE BatchId = @BatchId 
                 AND ProductId = @ProductId 
                 AND Quantity >= @Quantity 
                 AND IsActive = 1)
    BEGIN
        -- Insertar en la tabla correcta (LowInventory en lugar de InventoryLoss)
        INSERT INTO InventoryLoss(BatchId, Quantity, ProductId, UserId, Reason, RegisteredDate)
        VALUES (@BatchId, @Quantity, @ProductId, @UserId, @Reason, GETDATE())
        
        -- Descontar del stock del lote
        UPDATE ProductBatches 
        SET Quantity = Quantity - @Quantity
        WHERE BatchId = @BatchId 
          AND ProductId = @ProductId
        
        SET @Result = SCOPE_IDENTITY()
        SET @Message = 'REGISTRO EXITOSO C�D: 50008'
    END
    ELSE 
    BEGIN
        SET @Message = 'ERROR EN EL REGISTRO C�D: 50007'
    END
END
GO

--PROCEDIMIENTO PARA ACTUALIZAR BAJAS
CREATE PROC USP_EDITINVENTORYLOSS(
    @LowId INT,
    @BatchId INT,
    @Quantity INT,
    @ProductId INT,
    @UserId INT,
    @Reason NVARCHAR(200),
    @Message VARCHAR(500) OUTPUT,
    @Result INT OUTPUT
)
AS
BEGIN 
    SET NOCOUNT ON
    SET @Message = ''
    SET @Result = 0

    -- Buscar la baja existente
    DECLARE @PreviousAmount INT
    DECLARE @CurrentBatchId INT

    SELECT @PreviousAmount = Quantity, 
           @CurrentBatchId = BatchId 
    FROM InventoryLoss
    WHERE LowId = @LowId 
      AND ProductId = @ProductId

    IF @PreviousAmount IS NULL
    BEGIN 
        SET @Message = 'ERROR EN LA SOLICITUD C�D: 50009'
        RETURN
    END

    -- Calcular la diferencia
    DECLARE @Difference INT = @Quantity - @PreviousAmount

    -- Verificar si hay suficiente stock para aumentar la baja
    IF @Difference > 0 
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM ProductBatches 
                      WHERE BatchId = @BatchId 
                        AND ProductId = @ProductId 
                        AND Quantity >= @Difference 
                        AND IsActive = 1)
        BEGIN
            SET @Message = 'ERROR EN EL REGISTRO C�D: 50007'
            RETURN
        END
    END

    -- Actualizar la baja y ajustar el stock
    BEGIN TRY
        BEGIN TRANSACTION
        
        -- Actualizar el registro de baja
        UPDATE InventoryLoss SET 
            BatchId = @BatchId,
            Quantity = @Quantity,
            Reason = @Reason,
            UserId = @UserId
        WHERE LowId = @LowId 
          AND ProductId = @ProductId

        -- Ajustar el stock del lote
        UPDATE ProductBatches 
        SET Quantity = Quantity - @Difference
        WHERE BatchId = @BatchId 
          AND ProductId = @ProductId
        
        SET @Result = 1
        SET @Message = 'OPERACI�N EJECUTADA CON �XITO C�D: 50008'
        
        COMMIT TRANSACTION
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION
        SET @Message = 'ERROR EN LA ACTUALIZACI�N C�D: 50010 - ' + ERROR_MESSAGE()
    END CATCH
END
GO
--PROCEDIMIENTO PARA ELIMINAR BAJAS

CREATE PROC USP_DELETEINVENTORYLOSS(
    @LowId INT,
    @Message VARCHAR(500) OUTPUT,
    @Result INT OUTPUT
)
AS
BEGIN
    SET @Result = 0
    SET @Message = ''
    DECLARE @passed BIT = 1

    -- Verificamos que exista la baja
    IF EXISTS (SELECT * FROM InventoryLoss WHERE LowId = @LowId)
    BEGIN
        -- Recuperamos los datos necesarios
        DECLARE @BatchId INT
        DECLARE @ProductId INT
        DECLARE @Quantity INT

        SELECT @BatchId = BatchId,
               @ProductId = ProductId,
               @Quantity = Quantity
        FROM InventoryLoss 
        WHERE LowId = @LowId

        -- Revertimos el descuento en el stock del lote espec�fico
        UPDATE ProductBatches
        SET Quantity = Quantity + @Quantity
        WHERE BatchId = @BatchId 
          AND ProductId = @ProductId
          AND IsActive = 1

        -- Eliminamos la baja
        DELETE FROM InventoryLoss 
        WHERE LowId = @LowId

        SET @Result = 1
        SET @Message = 'OPERACI�N REALIZADA CON �XITO C�D: 50008'
    END
    ELSE
    BEGIN
        SET @passed = 0
        SET @Message = 'ERROR EN LA SOLICITUD C�D: 50009'
    END
END
GO

--PROCEDIMIENTO ALAMCENADO PARA AGREGAR UNA CATEGORIA


CREATE PROC USP_REGISTERCATEGORIES(
@CategoryName VARCHAR (65),
@CategoryDescription VARCHAR (300),
@IsActive BIT,
@Message VARCHAR(500) OUTPUT,
@Result INT OUTPUT
)
AS
BEGIN
SET NOCOUNT ON -- SET NOCOUNT ON ES EVITAR QUE SQL SERVER ENVIE UN MENSAJE DE VUELTA AL CLIENTE INDICANDO EL N�MERO DE FILAS AFECTADAS POR CADA INSTRUCCI�N 
SET @Message = ''
SET @Result = 0

IF NOT EXISTS( SELECT * FROM Categories WHERE CategoryName = @CategoryName AND CategoryDescription = @CategoryDescription)
BEGIN
INSERT INTO Categories(CategoryName, CategoryDescription ,RegisteredDate,Isactive)
VALUES             (@CategoryName,@CategoryDescription, GETDATE(), @IsActive)
SET @Result = SCOPE_IDENTITY()
END
ELSE
SET @Message = 'ERROR EN EL REGISTRO C�D: 50005'-- NO PUEDES AGREGAR ESTE DATO PORQUE YA EXISTE UNO ID�NTITO
END
GO


-- PROCEDIMIENTO ALMACENADO PARA EDITAR LOS DATOS UNA CATEGORIA
CREATE PROC USP_EDITCATEGORIES(
@CategoryId INT,
@CategoryName VARCHAR (65),
@CategoryDescription VARCHAR (300),
@IsActive BIT,
@Message VARCHAR(500) OUTPUT,
@Result INT OUTPUT

)
AS
BEGIN
SET NOCOUNT ON -- SET NOCOUNT ON ES EVITAR QUE SQL SERVER ENVIE UN MENSAJE DE VUELTA AL CLIENTE INDICANDO EL N�MERO DE FILAS AFECTADAS POR CADA INSTRUCCI�N 
SET @Message = ''
SET @Result = 0


IF NOT EXISTS (SELECT * FROM Categories WHERE CategoryName = @CategoryName and CategoryDescription = @CategoryDescription)
begin
UPDATE Categories SET 
CategoryName =  @CategoryName,
CategoryDescription = @CategoryDescription,
IsActive = @IsActive
WHERE CategoryId = @CategoryId
SET @Result = 1
END
ELSE
SET @Message = 'ERROR EN EL REGISTRO C�D: 50005'--NO PUEDES AGREGAR ESTE DATO PORQUE YA EXISTE UNO ID�NTITO
END
GO



--PROCEDIMIENTO PARA ELIMINAR UNA CATEGORIA

CREATE PROC USP_DELETECATEGORIES(
@CategoryId INT,
@Message VARCHAR(500) OUTPUT,
@Result INT OUTPUT
)
AS 
BEGIN
SET NOCOUNT ON -- SET NOCOUNT ON ES EVITAR QUE SQL SERVER ENVIE UN MENSAJE DE VUELTA AL CLIENTE INDICANDO EL N�MERO DE FILAS AFECTADAS POR CADA INSTRUCCI�N 
SET @Message = ''
SET @Result = 0
DECLARE @passed BIT = 1

IF EXISTS (SELECT * FROM Products P
            INNER JOIN Categories C ON C.CategoryId = P.CategoryId 
			WHERE P.CategoryId = @CategoryId
			)
			BEGIN
			SET @passed = 0
			SET @Result = 0
            SET @Message = @Message + 'ERROR EN LA SOLICITUD C�D: 50006' -- NO PUEDES ELIMINAR ESTE REGISTRO PORQUE ESTA SIENDO UTILIZADO EN OTRA PARTE
			END

IF (@passed = 1)
BEGIN
DELETE FROM Categories WHERE CategoryId = @CategoryId
SET @Result = 1
END
END
GO

----------------------------------------------------------fin en proceso-----------------------------------------------------------------------------------------------------

--PROCEDIMIENTO ALAMCENADO PARA AGREGAR CONCENTRACIONES DE LOS PRODUCTOS


CREATE OR ALTER PROC USP_REGISTERCONCENTRATION(
    @Volume VARCHAR(100),
    @Porcentage VARCHAR(100),
    @IsActive BIT
)
AS
BEGIN
    SET NOCOUNT ON; -- Evita mensajes de recuento de filas afectadas.

    BEGIN TRY
        -- Comprueba si ya existe una concentraci�n con el mismo volumen y porcentaje.
        IF NOT EXISTS (SELECT 1 FROM Concentration WHERE Volume = @Volume AND Porcentage = @Porcentage)
        BEGIN
            -- Si no existe, inserta el nuevo registro.
            INSERT INTO Concentration (Volume, Porcentage, RegisteredDate, Isactive)
            VALUES (@Volume, @Porcentage, GETDATE(), @IsActive);

            -- Devuelve el ID de la nueva concentraci�n como un conjunto de resultados.
            SELECT SCOPE_IDENTITY() AS NewConcentrationId;
        END
        ELSE
        BEGIN
            -- Si el registro ya existe, lanza el error de duplicado.
            -- C�D: 50005
           ;THROW 50005, 'Error de registro: Ya existe una concentraci�n con el mismo volumen y porcentaje.', 1;
        END

    END TRY
    BEGIN CATCH
        -- Vuelve a lanzar cualquier error capturado para que la aplicaci�n cliente lo reciba.
        THROW;
    END CATCH

    SET NOCOUNT OFF;
END
GO


-- PROCEDIMIENTO ALMACENADO PARA EDITAR LOS DATOS UNA CONCENTRACI�N
CREATE OR ALTER PROC USP_EDITCONCENTRATION(
    @ConcentrationId INT,
    @Volume VARCHAR(100),
    @Porcentage VARCHAR(100),
    @IsActive BIT
)
AS
BEGIN
    SET NOCOUNT ON; -- Evita mensajes de recuento de filas afectadas.

    BEGIN TRY
        -- Comprueba si la combinaci�n de volumen y porcentaje ya est� siendo utilizada por OTRA concentraci�n.
        IF NOT EXISTS (SELECT 1 FROM Concentration WHERE Volume = @Volume AND Porcentage = @Porcentage AND ConcentrationId != @ConcentrationId)
        BEGIN
            -- Si la combinaci�n es �nica, procede con la actualizaci�n.
            UPDATE Concentration SET
                Volume = @Volume,
                Porcentage = @Porcentage,
                IsActive = @IsActive
            WHERE ConcentrationId = @ConcentrationId;

            -- Verifica si la actualizaci�n afect� a alguna fila. Si no, la ConcentrationId no exist�a.
            IF @@ROWCOUNT = 0
            BEGIN
                -- C�D: 50009 - Sin Resultados (el registro a editar no se encontr�).
                ;THROW 50009, 'Error de edici�n: No se encontr� ninguna concentraci�n con el ID especificado.', 1;
            END
        END
        ELSE
        BEGIN
            -- Si la combinaci�n ya est� en uso por otro registro, lanza el error de duplicado.
            -- C�D: 50005
            ;THROW 50005, 'Error de edici�n: Ya existe otra concentraci�n con el mismo volumen y porcentaje.', 1;
        END

    END TRY
    BEGIN CATCH
        -- Vuelve a lanzar cualquier error capturado para que la aplicaci�n cliente lo reciba.
        THROW;
    END CATCH

    SET NOCOUNT OFF;
END
GO



--PROCEDIMIENTO PARA ELIMINAR UNA CATEGORIA

CREATE OR ALTER PROC USP_DELETECONCENTRATION(
    @ConcentrationId INT
)
AS
BEGIN
    SET NOCOUNT ON; -- Evita mensajes de recuento de filas afectadas.

    BEGIN TRY
        -- Comprueba si la concentraci�n est� vinculada a alg�n producto.
        IF EXISTS (SELECT 1 FROM Products WHERE ConcentrationId = @ConcentrationId)
        BEGIN
            -- Si existe una dependencia, lanza el error correspondiente y detiene la ejecuci�n.
            -- C�D: 50006
            ;THROW 50006, 'No se puede eliminar la concentraci�n porque est� asociada a uno o m�s productos.', 1;
        END

        -- Si no hay dependencias, procede con la eliminaci�n.
        DELETE FROM Concentration WHERE ConcentrationId = @ConcentrationId;

        -- Verifica si la eliminaci�n afect� a alguna fila.
        -- Si @@ROWCOUNT es 0, significa que la ConcentrationId no exist�a.
        IF @@ROWCOUNT = 0
        BEGIN
            -- Lanza un error indicando que el registro a eliminar no fue encontrado.
            -- C�D: 50009
            ;THROW 50009, 'Error de eliminaci�n: No se encontr� ninguna concentraci�n con el ID especificado.', 1;
        END

    END TRY
    BEGIN CATCH
        -- Vuelve a lanzar cualquier error capturado para que la aplicaci�n cliente lo reciba.
        THROW;
    END CATCH

    SET NOCOUNT OFF;
END
GO



--PROCEDIMIENTO ALAMCENADO PARA AGREGAR PRESENTACIONES DE LOS PRODUCTOS

CREATE OR ALTER PROC USP_REGISTERPRESENTATIONS(
    @PresentationDescription VARCHAR(150),
    @UnitMeasure VARCHAR(100),
    @Quantity INT,
    @IsActive BIT
)
AS
BEGIN
    SET NOCOUNT ON; -- Evita mensajes de recuento de filas afectadas.

    BEGIN TRY
        -- Comprueba si ya existe una presentaci�n con la misma descripci�n, unidad de medida y cantidad.
        IF NOT EXISTS (
            SELECT 1
            FROM Presentations
            WHERE
                PresentationDescription = @PresentationDescription AND
                UnitMeasure = @UnitMeasure AND
                quantity = @Quantity
        )
        BEGIN
            -- Si no existe, inserta el nuevo registro.
            INSERT INTO Presentations (PresentationDescription, UnitMeasure, quantity, RegisteredDate, Isactive)
            VALUES (@PresentationDescription, @UnitMeasure, @Quantity, GETDATE(), @IsActive);

            -- Devuelve el ID de la nueva presentaci�n como un conjunto de resultados.
            SELECT SCOPE_IDENTITY() AS NewPresentationId;
        END
        ELSE
        BEGIN
            -- Si el registro ya existe, lanza el error de duplicado.
            -- C�D: 50005
            ;THROW 50005, 'Error de registro: Ya existe una presentaci�n con la misma descripci�n, unidad de medida y cantidad.', 1;
        END

    END TRY
    BEGIN CATCH
        -- Vuelve a lanzar cualquier error capturado para que la aplicaci�n cliente lo reciba.
        THROW;
    END CATCH

    SET NOCOUNT OFF;
END
GO


-- PROCEDIMIENTO ALMACENADO PARA EDITAR LOS DATOS UNA CONCENTRACI�N
CREATE OR ALTER PROC USP_EDITPRESENTATIONS(
    @PresentationId INT,
    @PresentationDescription VARCHAR(150),
    @UnitMeasure VARCHAR(100),
    @Quantity INT,
    @IsActive BIT
)
AS
BEGIN
    SET NOCOUNT ON; -- Evita mensajes de recuento de filas afectadas.

    BEGIN TRY
        -- Comprueba si la combinaci�n de descripci�n, unidad y cantidad ya est� siendo utilizada por OTRA presentaci�n.
        IF NOT EXISTS (
            SELECT 1
            FROM Presentations
            WHERE
                PresentationDescription = @PresentationDescription AND
                UnitMeasure = @UnitMeasure AND
                quantity = @Quantity AND
                PresentationId != @PresentationId
        )
        BEGIN
            -- Si la combinaci�n es �nica, procede con la actualizaci�n.
            UPDATE Presentations SET
                PresentationDescription = @PresentationDescription,
                UnitMeasure = @UnitMeasure,
                quantity = @Quantity,
                IsActive = @IsActive
            WHERE PresentationId = @PresentationId;

            -- Verifica si la actualizaci�n afect� a alguna fila. Si no, la PresentationId no exist�a.
            IF @@ROWCOUNT = 0
            BEGIN
                -- C�D: 50009 - Sin Resultados (el registro a editar no se encontr�).
                ;THROW 50009, 'Error de edici�n: No se encontr� ninguna presentaci�n con el ID especificado.', 1;
            END
        END
        ELSE
        BEGIN
            -- Si la combinaci�n ya est� en uso por otro registro, lanza el error de duplicado.
            -- C�D: 50005
            ;THROW 50005, 'Error de edici�n: Ya existe otra presentaci�n con la misma descripci�n, unidad de medida y cantidad.', 1;
        END

    END TRY
    BEGIN CATCH
        -- Vuelve a lanzar cualquier error capturado para que la aplicaci�n cliente lo reciba.
        THROW;
    END CATCH

    SET NOCOUNT OFF;
END
GO


--PROCEDIMIENTO PARA ELIMINAR UNA PRESENTACI�N 

CREATE OR ALTER PROC USP_DELETEPRESENTATIONS(
    @PresentationId INT
)
AS
BEGIN
    SET NOCOUNT ON; -- Evita mensajes de recuento de filas afectadas.

    BEGIN TRY
        -- Comprueba si la presentaci�n est� vinculada a alg�n producto.
        IF EXISTS (SELECT 1 FROM Products WHERE PresentationId = @PresentationId)
        BEGIN
            -- Si existe una dependencia, lanza el error correspondiente y detiene la ejecuci�n.
            -- C�D: 50006
            ;THROW 50006, 'No se puede eliminar la presentaci�n porque est� asociada a uno o m�s productos.', 1;
        END

        -- Si no hay dependencias, procede con la eliminaci�n.
        DELETE FROM Presentations WHERE PresentationId = @PresentationId;

        -- Verifica si la eliminaci�n afect� a alguna fila.
        -- Si @@ROWCOUNT es 0, significa que la PresentationId no exist�a.
        IF @@ROWCOUNT = 0
        BEGIN
            -- Lanza un error indicando que el registro a eliminar no fue encontrado.
            -- C�D: 50009
            ;THROW 50009, 'Error de eliminaci�n: No se encontr� ninguna presentaci�n con el ID especificado.', 1;
        END

    END TRY
    BEGIN CATCH
        -- Vuelve a lanzar cualquier error capturado para que la aplicaci�n cliente lo reciba.
        THROW;
    END CATCH

    SET NOCOUNT OFF;
END
GO

-- maestro detalle


CREATE TYPE dbo.PurchaseDetailType AS TABLE (
    -- Un identificador de fila temporal para poder mapear los datos durante la transacci�n.
    RowId INT PRIMARY KEY,
    ProductId INT,
    BatchNumber NVARCHAR(100), -- N�mero de lote asignado por el proveedor/fabricante.
    ManufacturingDate DATE,    -- Fecha de fabricaci�n.
    ExpirationDate DATE,       -- Fecha de vencimiento.
    Quantity INT,
    UnitPrice DECIMAL(10, 2)
);
GO



CREATE OR ALTER PROC USP_REGISTERPURCHASE(
    @SupplierId INT,
    @UserId INT,
    @PurchaseNum VARCHAR(50),      -- N�mero de factura o comprobante del proveedor.
    @Observations NVARCHAR(500),
    @PurchaseDetails dbo.PurchaseDetailType READONLY -- Usamos nuestro nuevo tipo de tabla.
)
AS
BEGIN
    SET NOCOUNT ON;

    -- Inicia la transacci�n. Todas las operaciones siguientes son un "todo o nada".
    BEGIN TRANSACTION;

    BEGIN TRY
        
        -- 1. VALIDACIONES INICIALES (Como antes, ahora con validaci�n de fechas)
        

        IF NOT EXISTS (SELECT 1 FROM @PurchaseDetails)
        BEGIN
            ;THROW 50011, 'Error: La compra debe contener al menos un producto.', 1;
        END

        IF EXISTS (SELECT 1 FROM @PurchaseDetails WHERE ExpirationDate < GETDATE())
        BEGIN
            -- C�D: 50012 - Dato inv�lido (proponemos nuevo c�digo)
            ;THROW 50012, 'Error: No se pueden registrar productos con fecha de vencimiento pasada.', 1;
        END
        
        -- (Otras validaciones de existencia de proveedor, usuario y productos se mantienen...)
        IF NOT EXISTS (SELECT 1 FROM Suppliers WHERE SupplierId = @SupplierId) THROW 50009, 'Error: El proveedor especificado no existe.', 1;
        IF NOT EXISTS (SELECT 1 FROM Users WHERE UserId = @UserId) THROW 50009, 'Error: El usuario especificado no existe.', 1;
        
        DECLARE @InvalidProductId INT;
        SELECT TOP 1 @InvalidProductId = pd.ProductId FROM @PurchaseDetails pd LEFT JOIN Products p ON pd.ProductId = p.ProductId WHERE p.ProductId IS NULL;
        IF @InvalidProductId IS NOT NULL
        BEGIN
            DECLARE @ErrorMessage NVARCHAR(200) = FORMATMESSAGE('Error: El producto con ID %d no existe.', @InvalidProductId);
            THROW 50009, @ErrorMessage, 1;
        END

       
        -- 2. CREACI�N DE LOTES Y ACTUALIZACI�N DE INVENTARIO
       

        -- Tabla temporal para almacenar los nuevos IDs de lote generados.
        DECLARE @BatchMapping TABLE (
            RowId INT PRIMARY KEY,
            NewBatchId INT,
            ProductId INT,
            Quantity INT,
            UnitPrice DECIMAL(10, 2)
        );

        -- Usamos MERGE para insertar los nuevos lotes y capturar sus IDs generados
        -- junto con los datos originales del detalle de compra.
        MERGE INTO ProductBatches AS target
        USING @PurchaseDetails AS source
        ON 1 = 0 -- Condici�n siempre falsa para forzar una inserci�n (WHEN NOT MATCHED).
        WHEN NOT MATCHED THEN
            INSERT (BatchNumber, ManufacturingDate, ExpirationDate, Quantity, ProductId, RegisteredDate, Isactive)
            VALUES (source.BatchNumber, source.ManufacturingDate, source.ExpirationDate, source.Quantity, source.ProductId, GETDATE(), 1)
        -- La cl�usula OUTPUT nos permite capturar datos de la fila insertada (inserted.*)
        -- y de la fila original (source.*), guard�ndolos en nuestra tabla @BatchMapping.
        OUTPUT source.RowId, inserted.BatchId, source.ProductId, source.Quantity, source.UnitPrice
        INTO @BatchMapping (RowId, NewBatchId, ProductId, Quantity, UnitPrice);

        -- Ahora que tenemos los lotes creados, insertamos la cantidad disponible en la tabla Stock.
        INSERT INTO Stock (BatchId, AvailableQuantity, RegisteredDate)
        SELECT NewBatchId, Quantity, GETDATE()
        FROM @BatchMapping;

       
        -- 3. C�LCULO E INSERCI�N DE LA COMPRA (MAESTRO Y DETALLE)
        

        DECLARE @TotalPurchase DECIMAL(18, 2);
        SELECT @TotalPurchase = SUM(Quantity * UnitPrice) FROM @BatchMapping;

        INSERT INTO Purchases (SupplierId, UserId, Total, Observations, RegisteredDate, PurchaseNum)
        VALUES (@SupplierId, @UserId, @TotalPurchase, @Observations, GETDATE(), @PurchaseNum);

        DECLARE @NewPurchaseId INT = SCOPE_IDENTITY();

        -- Insertamos en el detalle de la compra usando los nuevos IDs de lote.
        INSERT INTO PurchasingDetail (PurchaseId, ProductId, BatchId, Quantity, UnitPrice, TotalPrice, RegisteredDate)
        SELECT
            @NewPurchaseId,
            ProductId,
            NewBatchId, -- Aqu� usamos el BatchId que generamos y capturamos.
            Quantity,
            UnitPrice,
            (Quantity * UnitPrice),
            GETDATE()
        FROM @BatchMapping;

        -- Si todo ha ido bien, se confirman todos los cambios de forma permanente.
        COMMIT TRANSACTION;

        -- Devuelve el ID de la nueva compra como confirmaci�n de �xito.
        SELECT @NewPurchaseId AS NewPurchaseId;

    END TRY
    BEGIN CATCH
        -- Si ocurre CUALQUIER error en el bloque TRY...
        IF @@TRANCOUNT > 0
        BEGIN
            -- Se revierten todos los cambios (inserts en Purchases, ProductBatches, Stock, etc.).
            ROLLBACK TRANSACTION;
        END
        -- Se relanza el error para que la aplicaci�n cliente lo reciba.
        ;THROW;
    END CATCH

    SET NOCOUNT OFF;
END
GO


--falta las ventas hacer sus maestro detalles recuerden que con una venta se genera una factura y detalle de venta 
--21/09/2025-- ultima fecha que se modific� los proc-- [william] [001]