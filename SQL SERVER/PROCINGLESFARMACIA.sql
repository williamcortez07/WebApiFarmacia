use PHARMACYSYSTEM0DB;
Go

/*
CÓDIGOS DE ERROR 
CÓD: 50005 -- REGISTRO DUPLICADO: Este error se genera cuando un usuario intenta insertar un registro que ya existe en la base de datos
              violando una regla de unicidad.Por ejemplo, intentar registrar un producto que ya esta registrado. 
CÓD: 50006   --REGISTRO CON DEPENDENCIAS: Este error se activa cuando se intenta eliminar un registro que está vinculado a otros datos importantes
              Por ejemplo, no se puede borrar un usuario porque ya tiene ventas asociadas; eliminarlo crearía una inconsistencia en los reportes de ventas.
CÓD: 50007 --STOCK INSUFICIENTE: Este error indica que la cantidad disponible en inventario es menor a la requerida para procesar una operación, como una
              venta o una baja de productos. SQL Server detecta esta condición y bloquea la transacción para evitar inconsistencias o valores negativos 
              en el stock.
CÓD: 50008 -- OPERACIÓN EXITOSA: La opereción se completó correctamente sin errores. Se confirma que el proceso fue exitoso y no se requieren acciones 
              adicionales.
CÓD: 50009 -- SIN RESULTADOS: Este error indica que no se han encontrado datos que cumplan con los criterios de búsqueda especificados. Indica que la
              consulta se ejecutó correctamente pero no retornó ningún registro.
CÓD: 50010 -- ERROR EN LA ATUALIZACIÓN DE DATOS: Este error indica que ocurrió un fallo inesperado durante el proceso de actualización en la base de 
              datos, impidiendo que los cambios se aplicaran correctamente. puede deberse a problemas de integridad referencial, conflictos de
              concurrencia, de conexión. El sistema debe manejar este error para preservar la consistencia de los datos y notificar a usuario 
              o sistema correspondiente.
CÓD: 50011 -- LA COMPRA DEBE TENER ALMENOS 1 PRODUCTO: [definir]

CÓD: 50012 -- NO SE PUDE REGISTRAR UN PRODUCTO VENCIDO: [definir]


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

            -- Opcional: Devuelve el ID del usuario recién creado.
            SELECT SCOPE_IDENTITY() AS NewUserId;
        END
        ELSE
        BEGIN
            -- Si el usuario ya existe, lanza un error personalizado.
            -- Formato: THROW [código_error], [mensaje], [estado]
            ;THROW 50005, 'Error de registro: El usuario ya existe y no puede ser duplicado.', 1;
        END
    END TRY
    -- Se inicia un bloque CATCH para manejar cualquier error que ocurra en el bloque TRY.
    BEGIN CATCH
        -- Vuelve a lanzar el error original para que la aplicación cliente lo reciba.
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
            -- Si el nombre es único, procede a actualizar los datos del usuario.
            UPDATE Users SET
                UserName = @Name,
                UserLastName = @LastName,
                UserPassword = @Password,
                Mail = @Mail,
                UserPhone = @Phone,
                IsActive = @IsActive,
                RolId = @RolId
            WHERE UserId = @UserId;

            -- Si la actualización no afectó a ninguna fila (porque el UserId no existe), se lanza un error.
            IF @@ROWCOUNT = 0
            BEGIN
                ;THROW 50004, 'Error de edición: El usuario con el ID especificado no fue encontrado.', 1;
            END
        END
        ELSE
        BEGIN
            -- Si ya existe otro usuario con ese nombre, lanza un error personalizado.
            -- Formato: THROW [código_error], [mensaje], [estado]
            ;THROW 50005, 'Error de edición: El nombre de usuario ya está en uso por otra cuenta.', 1;
        END
    END TRY
    -- Se inicia un bloque CATCH para manejar cualquier error que ocurra en el bloque TRY.
    BEGIN CATCH
        -- Vuelve a lanzar el error original para que la aplicación cliente lo reciba.
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
SET NOCOUNT ON -- SET NOCOUNT ON ES EVITAR QUE SQL SERVER ENVIE UN MENSAJE DE VUELTA AL CLIENTE INDICANDO EL NÚMERO DE FILAS AFECTADAS POR CADA INSTRUCCIÓN 
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
            SET @Message = @Message + 'ERROR EN LA SOLICITUD CÓD: 50006' -- NO PUEDES ELIMINAR ESTE REGISTRO PORQUE ESTA SIENDO UTILIZADO EN OTRA PARTE
			END
IF EXISTS (SELECT * FROM InventoryLoss LI
            INNER JOIN Users U ON U.UserId = LI.UserId -- LUEGO VERIFICA SI EL USUARIO NO HA REALIZADO UNA BAJA
			WHERE LI.UserId = @UserId
			)
			BEGIN
			SET @passed = 0
			SET @Result = 0
            SET @Message = @Message + 'ERROR EN LA SOLICITUD CÓD: 50006' -- NO PUEDES ELIMINAR ESTE REGISTRO PORQUE ESTA SIENDO UTILIZADO EN OTRA PARTE
			END
IF EXISTS (SELECT * FROM Invoices I
            INNER JOIN Users U ON U.UserId = I.UserId --LUEGO VERIFICA SI  EL USUARIO NO HA REALIZADO UNA FACTURA
			WHERE U.UserId = @UserId
			)
			BEGIN
			SET @passed = 0
			SET @Result = 0
SET @Message = @Message + 'ERROR EN LA SOLICITUD CÓD: 50006'-- NO PUEDES ELIMINAR ESTE REGISTRO PORQUE ESTA SIENDO UTILIZADO EN OTRA PARTE
			END
			IF(@passed = 1) -- SI EL PASO SIGUE SIENDO 1 ES PORQUE SU VALOR NO CAMBIO, NO ENTRÓ A LOS CONDICIONALES Y PROSIGUE CON LA ELIMINACIÓN
			BEGIN 
			DELETE FROM Users WHERE UserId = @UserId
			SET @Result = 1 -- EL resultado cambia a 1, osea todo salió bien
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
        -- Comprueba si ya existe un producto con la misma combinación de atributos únicos.
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

            -- Devuelve el ID del producto recién creado como un conjunto de resultados.
            SELECT SCOPE_IDENTITY() AS NewProductId;
        END
        ELSE
        BEGIN
            -- Si el producto ya existe, lanza el error de registro duplicado.
            -- CÓD: 50005
            ;THROW 50005, 'Error de registro: Ya existe un producto con el mismo nombre comercial, genérico, categoría, concentración, presentación y marca.', 1;
        END

    END TRY
    BEGIN CATCH
        -- Vuelve a lanzar cualquier error capturado para que la aplicación cliente lo reciba.
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
        -- Comprueba si el nuevo nombre comercial ya está siendo utilizado por OTRO producto.
        IF NOT EXISTS (
            SELECT 1
            FROM Products
            WHERE
                ProductTradeName = @ProductTradeName AND
                ProductId != @ProductId
        )
        BEGIN
            -- Si el nombre es único (o es el mismo del producto actual), procede con la actualización.
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

            -- Verifica si la actualización afectó a alguna fila. Si no, el ProductId no existía.
            IF @@ROWCOUNT = 0
            BEGIN
                -- CÓD: 50009 - Sin Resultados (el producto a editar no se encontró).
                ;THROW 50009, 'Error de edición: No se encontró ningún producto con el ID especificado.', 1;
            END
        END
        ELSE
        BEGIN
            -- Si el nombre comercial ya está en uso por otro producto, lanza el error de duplicado.
            -- CÓD: 50005
            ;THROW 50005, 'Error de edición: El nombre comercial del producto ya está en uso por otro producto.', 1;
        END

    END TRY
    BEGIN CATCH
        -- Vuelve a lanzar cualquier error capturado para que la aplicación cliente lo reciba.
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
        -- Se consolida la verificación de todas las dependencias en una sola consulta.
        -- Si el producto existe en CUALQUIERA de las tablas de detalle, se lanza un error.
        IF EXISTS (SELECT 1 FROM PurchasingDetail WHERE ProductId = @ProductId) OR
           EXISTS (SELECT 1 FROM SalesDetails WHERE ProductId = @ProductId) OR
           EXISTS (SELECT 1 FROM InventoryLoss WHERE ProductId = @ProductId)
        BEGIN
            -- Si se encuentra una dependencia, se lanza el error correspondiente y se detiene la ejecución.
            -- CÓD: 50006
            ;THROW 50006, 'No se puede eliminar el producto porque tiene registros asociados (detalles de compra, detalles de venta o bajas de inventario).', 1;
        END

        -- Si no hay dependencias, se procede con la eliminación.
        DELETE FROM Products WHERE ProductId = @ProductId;

        -- Se verifica si la eliminación afectó a alguna fila.
        -- Si @@ROWCOUNT es 0, significa que el ProductId no existía en la tabla Products.
        IF @@ROWCOUNT = 0
        BEGIN
            -- Se lanza un error indicando que el producto a eliminar no fue encontrado.
            -- CÓD: 50009
            ;THROW 50009, 'Error de eliminación: No se encontró ningún producto con el ID especificado.', 1;
        END

    END TRY
    BEGIN CATCH
        -- Vuelve a lanzar cualquier error capturado para que la aplicación cliente lo reciba.
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
        -- Comprueba si ya existe una marca con el mismo nombre y descripción.
        IF NOT EXISTS (SELECT 1 FROM Brands WHERE BrandName = @BrandName AND BrandDescription = @BrandDescription)
        BEGIN
            -- Si no existe, inserta la nueva marca.
            INSERT INTO Brands (BrandName, BrandDescription, Isactive, RegisteredDate)
            VALUES (@BrandName, @BrandDescription, @IsActive, GETDATE());

            -- Devuelve el ID de la marca recién creada como un conjunto de resultados.
            SELECT SCOPE_IDENTITY() AS NewBrandId;
        END
        ELSE
        BEGIN
            -- Si la marca ya existe, lanza el error de registro duplicado.
            -- CÓD: 50005
            ;THROW 50005, 'Error de registro: Ya existe una marca con el mismo nombre y descripción.', 1;
        END

    END TRY
    BEGIN CATCH
        -- Vuelve a lanzar cualquier error capturado para que la aplicación cliente lo reciba.
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
        -- Comprueba si el nuevo nombre de la marca ya está siendo utilizado por OTRA marca.
        IF NOT EXISTS (SELECT 1 FROM Brands WHERE BrandName = @BrandName AND BrandId != @BrandId)
        BEGIN
            -- Si el nombre es único, procede con la actualización.
            UPDATE Brands SET
                BrandName = @BrandName,
                BrandDescription = @BrandDescription,
                Isactive = @IsActive
            WHERE BrandId = @BrandId;

            -- Verifica si la actualización afectó a alguna fila. Si no, la BrandId no existía.
            IF @@ROWCOUNT = 0
            BEGIN
                -- CÓD: 50009 - Sin Resultados (la marca a editar no se encontró).
                ;THROW 50009, 'Error de edición: No se encontró ninguna marca con el ID especificado.', 1;
            END
        END
        ELSE
        BEGIN
            -- Si el nombre de la marca ya está en uso por otra, lanza el error de duplicado.
            -- CÓD: 50005
            ;THROW 50005, 'Error de edición: El nombre de la marca ya está en uso.', 1;
        END

    END TRY
    BEGIN CATCH
        -- Vuelve a lanzar cualquier error capturado para que la aplicación cliente lo reciba.
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
        -- Comprueba si la marca está vinculada a algún producto.
        IF EXISTS (SELECT 1 FROM Products WHERE BrandId = @BrandId)
        BEGIN
            -- Si existe una dependencia, lanza el error correspondiente y detiene la ejecución.
            -- CÓD: 50006
            ;THROW 50006, 'No se puede eliminar la marca porque está asociada a uno o más productos.', 1;
        END

        -- Si no hay dependencias, procede con la eliminación.
        DELETE FROM Brands WHERE BrandId = @BrandId;

        -- Verifica si la eliminación afectó a alguna fila.
        -- Si @@ROWCOUNT es 0, significa que la BrandId no existía.
        IF @@ROWCOUNT = 0
        BEGIN
            -- Lanza un error indicando que la marca a eliminar no fue encontrada.
            -- CÓD: 50009
            ;THROW 50009, 'Error de eliminación: No se encontró ninguna marca con el ID especificado.', 1;
        END

    END TRY
    BEGIN CATCH
        -- Vuelve a lanzar cualquier error capturado para que la aplicación cliente lo reciba.
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
SET NOCOUNT ON -- SET NOCOUNT ON ES EVITAR QUE SQL SERVER ENVIE UN MENSAJE DE VUELTA AL CLIENTE INDICANDO EL NÚMERO DE FILAS AFECTADAS POR CADA INSTRUCCIÓN 
SET @Message = ''
SET @Result = 0
  IF NOT EXISTS (SELECT * FROM Suppliers WHERE SupplierName = @SupplierName AND RNC = @RNC)
    BEGIN
  INSERT INTO  Suppliers(SupplierName, RNC,Mail,SupplierPhone,SupplierAddress, Isactive, RegisteredDate)VALUES
                     (@SupplierName, @RNC,@Mail,@SupplierPhone,@SupplierAddress, @IsActive, GETDATE())
     SET @Result = SCOPE_IDENTITY()

 END
  ELSE 
    SET @Message = 'ERROR EN EL REGISTRO CÓD: 50005'
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
SET @Message = 'ERROR EN EL REGISTRO CÓD: 50005'
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
            SET @Message = @Message + 'ERROR EN LA SOLICITUD CÓD: 50006'
			END
IF EXISTS (SELECT * FROM Purchases P  -- verifica si el proveedor no esta registrado en una compra
            INNER JOIN Suppliers S ON S.SupplierId = P.SupplierId
			WHERE S.SupplierId = @SupplierId
			)
			BEGIN
			SET @passed = 0
			SET @Result = 0
            SET @Message = @Message + 'ERROR EN LA SOLICITUD CÓD: 50006'
			END
IF EXISTS (SELECT * FROM SupplierBrand SB  -- verifica si el proveedor no esta relacionado con alguna marca
            INNER JOIN Suppliers S ON S.SupplierId = SB.SupplierId
			WHERE S.SupplierId = @SupplierId
			)
			BEGIN
			SET @passed = 0
			SET @Result = 0
            SET @Message = @Message + 'ERROR EN LA SOLICITUD CÓD: 50006'
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
        SET @Message = 'REGISTRO EXITOSO CÓD: 50008'
    END
    ELSE 
    BEGIN
        SET @Message = 'ERROR EN EL REGISTRO CÓD: 50007'
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
        SET @Message = 'ERROR EN LA SOLICITUD CÓD: 50009'
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
            SET @Message = 'ERROR EN EL REGISTRO CÓD: 50007'
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
        SET @Message = 'OPERACIÓN EJECUTADA CON ÉXITO CÓD: 50008'
        
        COMMIT TRANSACTION
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION
        SET @Message = 'ERROR EN LA ACTUALIZACIÓN CÓD: 50010 - ' + ERROR_MESSAGE()
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

        -- Revertimos el descuento en el stock del lote específico
        UPDATE ProductBatches
        SET Quantity = Quantity + @Quantity
        WHERE BatchId = @BatchId 
          AND ProductId = @ProductId
          AND IsActive = 1

        -- Eliminamos la baja
        DELETE FROM InventoryLoss 
        WHERE LowId = @LowId

        SET @Result = 1
        SET @Message = 'OPERACIÓN REALIZADA CON ÉXITO CÓD: 50008'
    END
    ELSE
    BEGIN
        SET @passed = 0
        SET @Message = 'ERROR EN LA SOLICITUD CÓD: 50009'
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
SET NOCOUNT ON -- SET NOCOUNT ON ES EVITAR QUE SQL SERVER ENVIE UN MENSAJE DE VUELTA AL CLIENTE INDICANDO EL NÚMERO DE FILAS AFECTADAS POR CADA INSTRUCCIÓN 
SET @Message = ''
SET @Result = 0

IF NOT EXISTS( SELECT * FROM Categories WHERE CategoryName = @CategoryName AND CategoryDescription = @CategoryDescription)
BEGIN
INSERT INTO Categories(CategoryName, CategoryDescription ,RegisteredDate,Isactive)
VALUES             (@CategoryName,@CategoryDescription, GETDATE(), @IsActive)
SET @Result = SCOPE_IDENTITY()
END
ELSE
SET @Message = 'ERROR EN EL REGISTRO CÓD: 50005'-- NO PUEDES AGREGAR ESTE DATO PORQUE YA EXISTE UNO IDÉNTITO
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
SET NOCOUNT ON -- SET NOCOUNT ON ES EVITAR QUE SQL SERVER ENVIE UN MENSAJE DE VUELTA AL CLIENTE INDICANDO EL NÚMERO DE FILAS AFECTADAS POR CADA INSTRUCCIÓN 
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
SET @Message = 'ERROR EN EL REGISTRO CÓD: 50005'--NO PUEDES AGREGAR ESTE DATO PORQUE YA EXISTE UNO IDÉNTITO
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
SET NOCOUNT ON -- SET NOCOUNT ON ES EVITAR QUE SQL SERVER ENVIE UN MENSAJE DE VUELTA AL CLIENTE INDICANDO EL NÚMERO DE FILAS AFECTADAS POR CADA INSTRUCCIÓN 
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
            SET @Message = @Message + 'ERROR EN LA SOLICITUD CÓD: 50006' -- NO PUEDES ELIMINAR ESTE REGISTRO PORQUE ESTA SIENDO UTILIZADO EN OTRA PARTE
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
        -- Comprueba si ya existe una concentración con el mismo volumen y porcentaje.
        IF NOT EXISTS (SELECT 1 FROM Concentration WHERE Volume = @Volume AND Porcentage = @Porcentage)
        BEGIN
            -- Si no existe, inserta el nuevo registro.
            INSERT INTO Concentration (Volume, Porcentage, RegisteredDate, Isactive)
            VALUES (@Volume, @Porcentage, GETDATE(), @IsActive);

            -- Devuelve el ID de la nueva concentración como un conjunto de resultados.
            SELECT SCOPE_IDENTITY() AS NewConcentrationId;
        END
        ELSE
        BEGIN
            -- Si el registro ya existe, lanza el error de duplicado.
            -- CÓD: 50005
           ;THROW 50005, 'Error de registro: Ya existe una concentración con el mismo volumen y porcentaje.', 1;
        END

    END TRY
    BEGIN CATCH
        -- Vuelve a lanzar cualquier error capturado para que la aplicación cliente lo reciba.
        THROW;
    END CATCH

    SET NOCOUNT OFF;
END
GO


-- PROCEDIMIENTO ALMACENADO PARA EDITAR LOS DATOS UNA CONCENTRACIÓN
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
        -- Comprueba si la combinación de volumen y porcentaje ya está siendo utilizada por OTRA concentración.
        IF NOT EXISTS (SELECT 1 FROM Concentration WHERE Volume = @Volume AND Porcentage = @Porcentage AND ConcentrationId != @ConcentrationId)
        BEGIN
            -- Si la combinación es única, procede con la actualización.
            UPDATE Concentration SET
                Volume = @Volume,
                Porcentage = @Porcentage,
                IsActive = @IsActive
            WHERE ConcentrationId = @ConcentrationId;

            -- Verifica si la actualización afectó a alguna fila. Si no, la ConcentrationId no existía.
            IF @@ROWCOUNT = 0
            BEGIN
                -- CÓD: 50009 - Sin Resultados (el registro a editar no se encontró).
                ;THROW 50009, 'Error de edición: No se encontró ninguna concentración con el ID especificado.', 1;
            END
        END
        ELSE
        BEGIN
            -- Si la combinación ya está en uso por otro registro, lanza el error de duplicado.
            -- CÓD: 50005
            ;THROW 50005, 'Error de edición: Ya existe otra concentración con el mismo volumen y porcentaje.', 1;
        END

    END TRY
    BEGIN CATCH
        -- Vuelve a lanzar cualquier error capturado para que la aplicación cliente lo reciba.
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
        -- Comprueba si la concentración está vinculada a algún producto.
        IF EXISTS (SELECT 1 FROM Products WHERE ConcentrationId = @ConcentrationId)
        BEGIN
            -- Si existe una dependencia, lanza el error correspondiente y detiene la ejecución.
            -- CÓD: 50006
            ;THROW 50006, 'No se puede eliminar la concentración porque está asociada a uno o más productos.', 1;
        END

        -- Si no hay dependencias, procede con la eliminación.
        DELETE FROM Concentration WHERE ConcentrationId = @ConcentrationId;

        -- Verifica si la eliminación afectó a alguna fila.
        -- Si @@ROWCOUNT es 0, significa que la ConcentrationId no existía.
        IF @@ROWCOUNT = 0
        BEGIN
            -- Lanza un error indicando que el registro a eliminar no fue encontrado.
            -- CÓD: 50009
            ;THROW 50009, 'Error de eliminación: No se encontró ninguna concentración con el ID especificado.', 1;
        END

    END TRY
    BEGIN CATCH
        -- Vuelve a lanzar cualquier error capturado para que la aplicación cliente lo reciba.
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
        -- Comprueba si ya existe una presentación con la misma descripción, unidad de medida y cantidad.
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

            -- Devuelve el ID de la nueva presentación como un conjunto de resultados.
            SELECT SCOPE_IDENTITY() AS NewPresentationId;
        END
        ELSE
        BEGIN
            -- Si el registro ya existe, lanza el error de duplicado.
            -- CÓD: 50005
            ;THROW 50005, 'Error de registro: Ya existe una presentación con la misma descripción, unidad de medida y cantidad.', 1;
        END

    END TRY
    BEGIN CATCH
        -- Vuelve a lanzar cualquier error capturado para que la aplicación cliente lo reciba.
        THROW;
    END CATCH

    SET NOCOUNT OFF;
END
GO


-- PROCEDIMIENTO ALMACENADO PARA EDITAR LOS DATOS UNA CONCENTRACIÓN
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
        -- Comprueba si la combinación de descripción, unidad y cantidad ya está siendo utilizada por OTRA presentación.
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
            -- Si la combinación es única, procede con la actualización.
            UPDATE Presentations SET
                PresentationDescription = @PresentationDescription,
                UnitMeasure = @UnitMeasure,
                quantity = @Quantity,
                IsActive = @IsActive
            WHERE PresentationId = @PresentationId;

            -- Verifica si la actualización afectó a alguna fila. Si no, la PresentationId no existía.
            IF @@ROWCOUNT = 0
            BEGIN
                -- CÓD: 50009 - Sin Resultados (el registro a editar no se encontró).
                ;THROW 50009, 'Error de edición: No se encontró ninguna presentación con el ID especificado.', 1;
            END
        END
        ELSE
        BEGIN
            -- Si la combinación ya está en uso por otro registro, lanza el error de duplicado.
            -- CÓD: 50005
            ;THROW 50005, 'Error de edición: Ya existe otra presentación con la misma descripción, unidad de medida y cantidad.', 1;
        END

    END TRY
    BEGIN CATCH
        -- Vuelve a lanzar cualquier error capturado para que la aplicación cliente lo reciba.
        THROW;
    END CATCH

    SET NOCOUNT OFF;
END
GO


--PROCEDIMIENTO PARA ELIMINAR UNA PRESENTACIÓN 

CREATE OR ALTER PROC USP_DELETEPRESENTATIONS(
    @PresentationId INT
)
AS
BEGIN
    SET NOCOUNT ON; -- Evita mensajes de recuento de filas afectadas.

    BEGIN TRY
        -- Comprueba si la presentación está vinculada a algún producto.
        IF EXISTS (SELECT 1 FROM Products WHERE PresentationId = @PresentationId)
        BEGIN
            -- Si existe una dependencia, lanza el error correspondiente y detiene la ejecución.
            -- CÓD: 50006
            ;THROW 50006, 'No se puede eliminar la presentación porque está asociada a uno o más productos.', 1;
        END

        -- Si no hay dependencias, procede con la eliminación.
        DELETE FROM Presentations WHERE PresentationId = @PresentationId;

        -- Verifica si la eliminación afectó a alguna fila.
        -- Si @@ROWCOUNT es 0, significa que la PresentationId no existía.
        IF @@ROWCOUNT = 0
        BEGIN
            -- Lanza un error indicando que el registro a eliminar no fue encontrado.
            -- CÓD: 50009
            ;THROW 50009, 'Error de eliminación: No se encontró ninguna presentación con el ID especificado.', 1;
        END

    END TRY
    BEGIN CATCH
        -- Vuelve a lanzar cualquier error capturado para que la aplicación cliente lo reciba.
        THROW;
    END CATCH

    SET NOCOUNT OFF;
END
GO

-- maestro detalle


CREATE TYPE dbo.PurchaseDetailType AS TABLE (
    -- Un identificador de fila temporal para poder mapear los datos durante la transacción.
    RowId INT PRIMARY KEY,
    ProductId INT,
    BatchNumber NVARCHAR(100), -- Número de lote asignado por el proveedor/fabricante.
    ManufacturingDate DATE,    -- Fecha de fabricación.
    ExpirationDate DATE,       -- Fecha de vencimiento.
    Quantity INT,
    UnitPrice DECIMAL(10, 2)
);
GO



CREATE OR ALTER PROC USP_REGISTERPURCHASE(
    @SupplierId INT,
    @UserId INT,
    @PurchaseNum VARCHAR(50),      -- Número de factura o comprobante del proveedor.
    @Observations NVARCHAR(500),
    @PurchaseDetails dbo.PurchaseDetailType READONLY -- Usamos nuestro nuevo tipo de tabla.
)
AS
BEGIN
    SET NOCOUNT ON;

    -- Inicia la transacción. Todas las operaciones siguientes son un "todo o nada".
    BEGIN TRANSACTION;

    BEGIN TRY
        
        -- 1. VALIDACIONES INICIALES (Como antes, ahora con validación de fechas)
        

        IF NOT EXISTS (SELECT 1 FROM @PurchaseDetails)
        BEGIN
            ;THROW 50011, 'Error: La compra debe contener al menos un producto.', 1;
        END

        IF EXISTS (SELECT 1 FROM @PurchaseDetails WHERE ExpirationDate < GETDATE())
        BEGIN
            -- CÓD: 50012 - Dato inválido (proponemos nuevo código)
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

       
        -- 2. CREACIÓN DE LOTES Y ACTUALIZACIÓN DE INVENTARIO
       

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
        ON 1 = 0 -- Condición siempre falsa para forzar una inserción (WHEN NOT MATCHED).
        WHEN NOT MATCHED THEN
            INSERT (BatchNumber, ManufacturingDate, ExpirationDate, Quantity, ProductId, RegisteredDate, Isactive)
            VALUES (source.BatchNumber, source.ManufacturingDate, source.ExpirationDate, source.Quantity, source.ProductId, GETDATE(), 1)
        -- La cláusula OUTPUT nos permite capturar datos de la fila insertada (inserted.*)
        -- y de la fila original (source.*), guardándolos en nuestra tabla @BatchMapping.
        OUTPUT source.RowId, inserted.BatchId, source.ProductId, source.Quantity, source.UnitPrice
        INTO @BatchMapping (RowId, NewBatchId, ProductId, Quantity, UnitPrice);

        -- Ahora que tenemos los lotes creados, insertamos la cantidad disponible en la tabla Stock.
        INSERT INTO Stock (BatchId, AvailableQuantity, RegisteredDate)
        SELECT NewBatchId, Quantity, GETDATE()
        FROM @BatchMapping;

       
        -- 3. CÁLCULO E INSERCIÓN DE LA COMPRA (MAESTRO Y DETALLE)
        

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
            NewBatchId, -- Aquí usamos el BatchId que generamos y capturamos.
            Quantity,
            UnitPrice,
            (Quantity * UnitPrice),
            GETDATE()
        FROM @BatchMapping;

        -- Si todo ha ido bien, se confirman todos los cambios de forma permanente.
        COMMIT TRANSACTION;

        -- Devuelve el ID de la nueva compra como confirmación de éxito.
        SELECT @NewPurchaseId AS NewPurchaseId;

    END TRY
    BEGIN CATCH
        -- Si ocurre CUALQUIER error en el bloque TRY...
        IF @@TRANCOUNT > 0
        BEGIN
            -- Se revierten todos los cambios (inserts en Purchases, ProductBatches, Stock, etc.).
            ROLLBACK TRANSACTION;
        END
        -- Se relanza el error para que la aplicación cliente lo reciba.
        ;THROW;
    END CATCH

    SET NOCOUNT OFF;
END
GO


--falta las ventas hacer sus maestro detalles recuerden que con una venta se genera una factura y detalle de venta 
--21/09/2025-- ultima fecha que se modificó los proc-- [william] [001]